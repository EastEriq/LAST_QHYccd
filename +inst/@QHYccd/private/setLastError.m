function setLastError(QC,retcode,msg)
% helper to set QC.LastError empty or message
    if retcode==0
        QC.LastError='';
    else
        try
            QC.reportError('%s: %s',msg,inst.qhyccdError(typecast(uint32(retcode),'int32')));
        catch
            QC.reportError('%s',msg)
        end
    end
end
