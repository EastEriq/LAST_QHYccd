function success=disconnect(QC)
    % Close the connection with the camera registered in the
    %  current camera object

    % don't try co lose an invalid camhandle, it would crash matlab
    if ~isempty(QC.camhandle)
        % check this status, which may fail
        success=(CloseQHYCCD(QC.camhandle)==0);
    else
        success=true;
    end
    % null the handle so that other methods can't talk anymore to it
    QC.camhandle=[];
    
    QC.setLastError(success,'could not disconnect camera')

end
