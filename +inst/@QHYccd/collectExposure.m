function img=collectExposure(QC,varargin)
% collect the exposed frame, but only if an exposure was started!

    switch QC.CamStatus
        case {'exposing','reading'}

            QC.reportDebug('t before calling GetQHYCCDSingleFrame: %f\n',toc);
            [ret,w,h,bp,channels]=...
                GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);
            QC.reportDebug('t after calling GetQHYCCDSingleFrame: %f\n',toc);
            QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                % even if a subsequent
                                                % exposure is started
            if ret==0
                QC.TimeEnd=now;
                QC.ProgressiveFrame=1;
                % Conversion of an image buffer to a matlab image
                img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
                QC.reportDebug('t after unpacking buffer: %f\n',toc)
                QC.deallocate_image_buffer
            else
                QC.report(['error retrieving frame from camera ' QC.CameraName '\n'])
                QC.TimeEnd=[];
                img=[];
            end

            QC.setLastError(ret==0,'could not retrieve exposure from camera');
            if ret==0
                QC.CamStatus='idle';
            else
                QC.CamStatus='unknown';
            end
        otherwise
            QC.reportError='no image to read because exposure not started';
            img=[];
    end

    QC.LastImage=img;
    QC.reportDebug('t after copying LastImage: %f\n',toc)

    QC.LastImageSaved=false;

    if ~isempty(QC.ImageHandler)
        QC.ImageHandler(QC,varargin{:})
    end

end
