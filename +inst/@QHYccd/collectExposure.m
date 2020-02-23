function img=collectExposure(QC)
% collect the exposed frame

    [ret,w,h,bp,channels]=...
        GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);

    if ret==0
        t_readout=now;
        QC.progressive_frame=1;
    else
        t_readout=[];
    end
    
    img=unpackImgBuffer(QC.pImg,w,h,channels,bp);

    QC.deallocate_image_buffer

    QC.setLastError(ret==0,'could retrieve exposure from camera');

end
