function setLastError(QC,success,msg)
% helper to set QC.lastError empty or message
    if success
        QC.lastError='';
    else
        QC.lastError=msg;
    end
end
