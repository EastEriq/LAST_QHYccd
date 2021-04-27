function abort(QC)
% Stop any ongoing acquisition, stopping also the image collector timer
%  if there was one defined for this camera

% call both stopping functions, how could we know
% in which acquisition mode we are? Eventually, checking QC.StreamMode,
%  though that doesn't say if an exposure was started at all or not

% stop the image collector timer, if there is one active
    stop(timerfind('Name',sprintf('ImageCollector-%d',QC.CameraNum)));

% stopping single image exposure
    CancelQHYCCDExposingAndReadout(QC.camhandle);
% stopping live mode
    StopQHYCCDLive(QC.camhandle);

    deallocate_image_buffer(QC)
    
    QC.CamStatus='idle';
    
end
