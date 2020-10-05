function setLastError(QC,success,msg)
% helper to set QC.LastError empty or message
    if success
        QC.LastError='';
    else
        QC.LastError=msg;
    end
end
