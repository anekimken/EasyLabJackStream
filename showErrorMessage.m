function string=showErrorMessage(e)
% showErrorMessage Displays the UD or .NET error from a MATLAB exception.

if(isa(e, 'NET.NetException'))
    eNet = e.ExceptionObject;
    if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
        disp(['UD Error: ' char(eNet.ToString())])
        disp(e.ExceptionObject)
        string=ToString(e.ExceptionObject)
    else
%         disp(['.NET Error: ' char(eNet.ToString())])
    end
end
disp(getReport(e))
end