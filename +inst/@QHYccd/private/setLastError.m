function setLastError(QC,success,msg)
% helper to set QC.LastError empty or message
    if success==0
        QC.LastError='';
    else
        try
            QC.reportError('%s: %s',msg,inst.qhyccdError(typecast(uint32(success),'int32')));
        catch
            QC.reportError('%s',msg)
        end
    end
end
