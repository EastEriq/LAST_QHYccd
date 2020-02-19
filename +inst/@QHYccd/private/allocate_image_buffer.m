function allocate_image_buffer(QC)
    % Allocate the image buffer. The maximal length is in fact only
    %  needed only for full frame color images including overscan
    %  areas; for all other cases (notably when only a ROI, or binning
    %  is requested) it probably could be smaller, making transfer
    %  time much shorter. However, the SDK doesn't provide a safe way
    %  to determine this size, and hence we allocate a lot to stay
    %  safe from segfaults.
    imlength=GetQHYCCDMemLength(QC.camhandle);
    QC.pImg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
end
