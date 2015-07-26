function [RecordedData,data] = StreamData(DataRate,NumberOfChannels,TimeToStream)
% STREAMDATA records voltage data using a LabJack
%
% STREAMDATA uses the class labJackU6 to talk to the DAQ
%

%% Preemptively check user inputs
if NumberOfChannels>4
    error('Too many channels! Max number of channels is 4.')
else if NumberOfChannels<=0
        error('Please specify number of channels between 1 and 4')
    end
end


if ispc % check for windows
    
    %% Start talking to LabJack and setup the channels
    [ljudObj,ljhandle,chanType] = LabJackInit_PC(DataRate,NumberOfChannels);
    
    
    
    
end



if ismac %check for mac
    %% Start talking to LabJack
    lbj=labJackU6;
    open(lbj);
    if ~(lbj.isOpen)
        error('Failed to open LabJack. Check connections.')
    end
    
    % lbj.verbose=3;
    
    
    %% Setup LabJack
    lbj.SampleRateHz=DataRate;
    lbj.ResolutionADC=6;
    
    for i=1:NumberOfChannels
        ChannelList(i)=i-1;
        Gains(i)=10;
        Polar(i)='s';
    end
    
    addChannel(lbj,ChannelList,Gains,Polar); % add channels 0 & 1, range +/- 10V, single-ended
    
    if streamConfigure(lbj)
        error('Error configuring stream. Try again.')
    end
    
end


%% Set up Matlab for both platforms
RecordedData=zeros(DataRate*TimeToStream,NumberOfChannels);
% size(RecordedData)
index=1;
MinuteCount=0;
FS=stoploop('Done with experiment?');

if ispc
    data = NET.createArray('System.Double', DataRate*1*NumberOfChannels);  %Max buffer size (#channels*numScansRequested) for reading both channels
end


%% Take data

if ispc
    
    try
        
        scansRequested = ceil(0.1*DataRate*NumberOfChannels); %read data at 10 Hz
        
        
        %Start the stream.
        chanObj = System.Enum.ToObject(chanType, 1); %channel = 0
        [ljerror, dblValue] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.START_STREAM, chanObj, 0, 0);
        
        
        tic
        while (~FS.Stop() && toc<=TimeToStream)
            %             pause(0.1)
            [ljerror, PacketLength] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_STREAM_DATA, LabJack.LabJackUD.CHANNEL.ALL_CHANNELS, scansRequested, data);
            for  j= 1:NumberOfChannels:PacketLength*NumberOfChannels
                for k=1:NumberOfChannels
                    RecordedData(index+(j-1)/NumberOfChannels,k)=data(j+k-1);
                end
            end
            index=index+PacketLength;
            if toc>60*MinuteCount
                disp([num2str(MinuteCount) ' minutes elapsed.'])
                MinuteCount=MinuteCount+1;
            end
        end
        
    catch err
        
        if strncmp(char(err.ExceptionObject.ToString()),'Stream scans overlapped',10)
            disp('Try a slower sampling rate or lower resolution. See https://labjack.com/support/datasheets/u6/operation/stream-mode for details.')
        else
            disp(ljerror)
        end
        FS.Clear();
        closepreview
        %Stop the stream to avoid memory leak
        chanObj = System.Enum.ToObject(chanType, 0); %channel = 0
%         ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.STOP_STREAM, chanObj, 0, 0);
        
        rethrow(err)
    end
    
end

if ismac
    startStream(lbj);
    tic
    while (~FS.Stop() && toc<=TimeToStream)
        [data,errorcode]=getStreamData(lbj);
        if errorcode==55
            disp('Try a slower sampling rate or lower resolution. See https://labjack.com/support/datasheets/u6/operation/stream-mode for details.')
            break
        end
        PacketLength=size(data,1);
        RecordedData(index:index+PacketLength-1,:)=data;
        index=index+PacketLength;
        if toc>60*MinuteCount
            disp([num2str(MinuteCount) ' minutes elapsed.'])
            MinuteCount=MinuteCount+1;
        end
    end
end

if index<size(RecordedData,1) %get rid of extra space that was allocated if necessary
    RecordedData=RecordedData(1:index-1,:);
end

%% Clean up
if ismac
    stopStream(lbj);
elseif ispc
    chanObj = System.Enum.ToObject(chanType, 0); %channel = 0
    ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.STOP_STREAM, chanObj, 0, 0);
end

FS.Clear();




end