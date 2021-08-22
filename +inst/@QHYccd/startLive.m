function startLive(QC)
% Start exposure in Live stream mode. Images can be retrieved calling
%  (repeatedly when needed) Q.collectLiveExposure(). Fortunately with the
%  lastest SDK (21-3-30), it is not mandatory to retrieve EACH new frame
%  periodically from the camera, and thus collectLiveExposure() can be
%  called sporadically.
% Live mode must be then stopped with Q.abort().

    QC.initStreamMode(1);
    if QC.Verbose>1
        fprintf('t after eventual reinitialization: %f\n',toc);
    end

    QC.ExpTime=QC.ExpTime;
    if QC.Verbose>1
        fprintf('t after setting again parameters: %f\n',toc);
    end

    QC.allocate_image_buffer
    if QC.Verbose>1
        fprintf('t after allocating buffer: %f\n',toc);
    end

    t0=now;
    ret=BeginQHYCCDLive(QC.camhandle);
    QC.ProgressiveFrame=0;
    QC.TimeStartDelta=now-t0;
    if QC.Verbose>1
        fprintf('t after BeginQHYCCDLive: %f\n',toc);
    end
    if ret==0
        QC.CamStatus='exposing';
    else
        QC.CamStatus='unknown';
        QC.deallocate_image_buffer
        QC.LastError='could not start Live exposure';
    end
