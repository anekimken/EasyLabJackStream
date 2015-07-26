function [ljudObj,ljhandle,chanType] = LabJackInit_PC(scanRate)

%LabJackInit for Eyebrow Hair Swipe Study
%Based on example MATLAB code provided by LabJack
%Initializes LabJack into ready mode for data acquisition

%Who                When                       What
%Adam Nekimken      13 March, 2014 4:00 pm     Started Coding


ljasm = NET.addAssembly('LJUDDotNet'); %Make the LabJack driver .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD; %create UD object for LabJack

ioType = LabJack.LabJackUD.IO; %configure variable ioType to call LabJack.LabJackUD.IO in LJ driver
channel = LabJack.LabJackUD.CHANNEL; %configure variable channel to call LabJack.LabJackUD.CHANNEL in LJ driver


%Initialize parameters
dblValue = 0;

%scanRate = 1000;

% Variables to satisfy certain method signatures
dummyInt = 0;
dummyDouble = 0;


%Read and display the UD version.
disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

try
    %Open and configure LabJack
    %Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U6, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Configure the resolution of the analog inputs (pass a non-zero value for quick sampling).
    %See section 2.6 / 3.1 of LJ U6 user guide for more information.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.AIN_RESOLUTION, 0, 0, 0);
    
    %Configure the analog input range on channels 0,1,2 and 3 for bipolar +-10 volts (LJ_rgBIP10V = 2).
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 0, 2, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 1, 2, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 2, 2, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 3, 2, 0, 0);
    
    %Set the scan rate.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_SCAN_FREQUENCY, scanRate, 0, 0);
    
    %Give the driver a 5 second buffer (scanRate * 4 channels * 5 seconds).
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_BUFFER_SIZE, scanRate*5*4, 0, 0);
    
    %Configure reads to retrieve data when requested number of scans are
    %ready. LabJack controls timing of sampling now, but we only take new
    %samples if we can get all of them. (this is what the 2 is for)
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.STREAM_WAIT_MODE, 2, 0, 0);
    
    %Define the scan list as AIN0, then AIN1, then AIN2, then AIN3
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.CLEAR_STREAM_CHANNELS, 0, 0, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.ADD_STREAM_CHANNEL, 0, 0, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.ADD_STREAM_CHANNEL, 1, 0, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.ADD_STREAM_CHANNEL, 2, 0, 0, 0);
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.ADD_STREAM_CHANNEL, 3, 0, 0, 0);
    
    
    
    %Execute the list of requests.
    ljudObj.GoOne(ljhandle);
    
    %Get all the results just to check for errors.
    [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetFirstResult(ljhandle, ioType, channel, dblValue, dummyInt, dummyDouble);
    finished = false;
    while finished == false
        try
            [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetNextResult(ljhandle, ioType, channel, dblValue, dummyInt, dummyDouble);
        catch e
            if(isa(e, 'NET.NetException'))
                eNet = e.ExceptionObject;
                if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
                    if(eNet.LJUDError == LabJack.LabJackUD.LJUDERROR.NO_MORE_DATA_AVAILABLE)
                        finished = true;
                    end
                end
            end
            %Report non NO_MORE_DATA_AVAILABLE error.
            if(finished == false)
                throw(e)
            end
        end
    end
    
    %Used for casting a value to a CHANNEL enum
    chanType = LabJack.LabJackUD.CHANNEL.LOCALID.GetType;
    
    %Start the stream.
    chanObj = System.Enum.ToObject(chanType, 1); %channel = 0
    [ljerror, dblValue] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.START_STREAM, chanObj, 0, 0);
    
    %The actual scan rate is dependent on how the desired scan rate divides into
    %the LabJack clock.  The actual scan rate is returned in the value parameter
    %from the start stream command.
    disp(['Actual Scan Rate = ' num2str(dblValue)])
    disp(['Actual Sample Rate = ' num2str(dblValue) sprintf('\n')]) % # channels * scan rate
   
    
catch err
    showErrorMessage(err)
    rethrow(err)
    
end

end %end LabJackInit Func