function success=disconnect(QC)
    % Close the connection with the camera registered in the
    %  current camera object

    % don't try to close an invalid camhandle, it would crash matlab
    if ~isempty(QC.camhandle)
        % maybe for safety here we could attempt to call StopQHYCCDLive(QC.camhandle)
        %  or would this cause a crash if live mode was never started?
        % StopQHYCCDLive(QC.camhandle);
        %
        % check this status, which may fail
        QC.reportDebug('calling CloseQHYCCD\n')
        ret=CloseQHYCCD(QC.camhandle);
        QC.setLastError(ret,'could not disconnect camera')
        success=(ret==0);
    else
        success=true;
    end
    % null the handle so that other methods can't talk anymore to it
    QC.camhandle=[];
end
