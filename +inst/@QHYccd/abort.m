function abort(QC)
% Cleaning up after taking a sequence of images

    StopQHYCCDLive(QC.camhandle);

    % delete objects, release pImg, but check first that they
    %  exist. This to suppress warnings if this function is called twice,
    %  or when acquisition hasn't been started at all

    QC.deallocate_image_buffer(QC)

end
