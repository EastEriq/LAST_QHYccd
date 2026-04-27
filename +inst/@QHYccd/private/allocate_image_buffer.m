function allocate_image_buffer(QC)
    % Allocate the image buffer. The maximal length is in fact only
    %  needed only for full frame color images including overscan
    %  areas; for all other cases (notably when only a ROI, or binning
    %  is requested) it probably could be smaller, making transfer
    %  time much shorter. However, the SDK doesn't provide a safe way
    %  to determine this size, and hence we allocate a lot to stay
    %  safe from segfaults.
    % this renders invariably imglength=9700*6522*4 (doh?) for the QHY600
    %  which instead has a 9600*6422*2bytes sensor
    %imlength=GetQHYCCDMemLength(QC.camhandle);
    % alternative computation (unsafe Re: color)
    roi=QC.ROI; % not suported by 2021 SDK
    if isempty(roi)
        imlength=QC.physical_size.nx * QC.physical_size.ny * QC.BitDepth/2;
        % consider also QC.effective_area which removes overscans
    else
        imlength=(roi(3)-roi(1)+1) * (roi(4)-roi(2)+1)* QC.BitDepth/8;
    end
    if QC.StreamMode==1 && QC.SharedRingBufferDim>0
        try
            QC.pImg= POSIXipc.shm(sprintf('C%s_image_ringbuffer_1',...
                                   QC.Id), imlength);% in case it was ealier [] or libpointer
            for i=2:QC.SharedRingBufferDim
                QC.pImg(i)=POSIXipc.shm(sprintf('C%s_image_ringbuffer_%d',...
                                                 QC.Id, i), imlength);
            end
        catch AE
            QC.reportError('cannot allocate image ringbuffer: %s',AE.message)
            % the fallback for QC.pImg is "what it was before". To assess
            %  whether this is the right choice or will cause problems
        end
    else
        QC.pImg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
    end
end
