function allocate_image_buffer(QC)
    % Allocate the image buffer. The maximal length is in fact only
    %  needed only for full frame color images including overscan
    %  areas; for all other cases (notably when only a ROI, or binning
    %  is requested) it probably could be smaller, making transfer
    %  time much shorter. However, the SDK doesn't provide a safe way
    %  to determine this size, and hence we allocate a lot to stay
    %  safe from segfaults.
    imlength=GetQHYCCDMemLength(QC.camhandle);
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
        end
    else
        QC.pImg=libpointer('uint8Ptr',zeros(imlength,1,'uint8'));
    end
end
