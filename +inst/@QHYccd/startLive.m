function startLive(QC)
% Start exposure in Live stream mode. Images can be retrieved calling
%  (repeatedly when needed) Q.collectLiveExposure(). Fortunately with the
%  lastest SDK (21-3-30), it is not mandatory to retrieve EACH new frame
%  periodically from the camera, and thus collectLiveExposure() can be
%  called sporadically.
% Live mode must be then stopped with Q.abort().

    QC.initStreamMode(1);
    QC.reportDebug('t after eventual reinitialization: %f\n',toc)

    QC.ExpTime=QC.ExpTime;
    QC.reportDebug('t after setting again exposure time: %f\n',toc)

    QC.allocate_image_buffer
    QC.reportDebug('t after allocating buffer: %f\n',toc)

    t0=now;
    QC.reportDebug('calling BeginQHYCCDLive\n')
    ret=BeginQHYCCDLive(QC.camhandle);
    QC.ProgressiveFrame=0;
    QC.TimeStartDelta=now-t0;
    QC.reportDebug('t after BeginQHYCCDLive: %f\n',toc)

    if ret==0
        QC.CamStatus='exposing';
    else
        QC.CamStatus='unknown';
        QC.deallocate_image_buffer
        QC.LastError='could not start Live exposure';
    end
