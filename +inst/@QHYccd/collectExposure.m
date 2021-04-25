function img=collectExposure(QC,varargin)
% collect the exposed frame, but only if an exposure was started!

    switch QC.CamStatus
        case {'exposing','reading'}

            if QC.verbose>1
                fprintf('t before calling GetQHYCCDSingleFrame: %f\n',toc);
            end
            [ret,w,h,bp,channels]=...
                GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);
            if QC.verbose>1 
                fprintf('t after calling GetQHYCCDSingleFrame: %f\n',toc);
            end
            QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                % even if a subsequent
                                                % exposure is started
            if ret==0
                QC.TimeEnd=now;
                QC.progressive_frame=1;
                % Conversion of an image buffer to a matlab image
                img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
                if QC.verbose>1
                    fprintf('t after unpacking buffer: %f\n',toc);
                end
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
            QC.LastError='no image to read because exposure not started';
            img=[];
    end

    QC.LastImage=img;
    if QC.verbose>1
        fprintf('t after copying LastImage: %f\n',toc);
    end
    QC.LastImageSaved=false;

    if ~isempty(QC.ImageHandler)
        QC.ImageHandler(QC,varargin{:})
    end

end
