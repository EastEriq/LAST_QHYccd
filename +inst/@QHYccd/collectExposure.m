function img=collectExposure(QC)
% collect the exposed frame, but only if an exposure was started!

    switch QC.CamStatus
        case {'exposing','reading'}

            % fprintf('t before calling GetQHYCCDSingleFrame: %f\n',toc);
            [ret,w,h,bp,channels]=...
                GetQHYCCDSingleFrame(QC.camhandle,QC.pImg);
            % fprintf('t after calling GetQHYCCDSingleFrame: %f\n',toc);
            
            QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                % even if a subsequent
                                                % exposure is started
            if ret==0
                QC.TimeEnd=now;
                QC.progressive_frame=1;
            else
                QC.TimeEnd=[];
            end

            % Conversion of an image buffer to a matlab image
            img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
            % fprintf('t after unpacking buffer: %f\n',toc);

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
    % fprintf('t after copying LastImage: %f\n',toc);
    QC.LastImageSaved=false;

end
