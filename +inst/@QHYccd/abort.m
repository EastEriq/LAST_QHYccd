function abort(QC)
% call both stopping functions, how could we know
% in which acquisition mode we are?

% stopping single image exposure
    CancelQHYCCDExposingAndReadout(QC.camhandle);
% stopping live mode
    StopQHYCCDLive(QC.camhandle);

    deallocate_image_buffer(QC)

    QC.CamStatus='idle';
    
end
