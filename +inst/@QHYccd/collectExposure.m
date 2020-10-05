function img=collectExposure(QC)
% collect the exposed frame, but only if an exposure was started!

    switch QC.CamStatus
        case {'exposing','reading'}

            [ret,w,h,bp,channels]=...
                GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);

            if ret==0
                QC.time_end=now;
                QC.progressive_frame=1;
            else
                QC.time_end=[];
            end

            img=unpackImgBuffer(QC.pImg,w,h,channels,bp);

            QC.deallocate_image_buffer

            QC.setLastError(ret==0,'could not retrieve exposure from camera');
            if ret==0
                QC.CamStatus='idle';
            else
                QC.CamStatus='unknown';
            end
        otherwise
            QC.LastError='no image to read because exposure not started';
            img=[];
    end
    
    QC.LastImage=img;

end
