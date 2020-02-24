function startExposure(QC,expTime)
% set up the scenes for taking a single exposure

    switch QC.CamStatus
        case {'idle','unknown'} % shall we try exposing for 'unknown' too?
            if exist('expTime','var')
                QC.ExpTime=expTime;
            end

            QC.progressive_frame=0;

            QC.allocate_image_buffer

            SetQHYCCDStreamMode(QC.camhandle,0);

            t0=now;
            ret=ExpQHYCCDSingleFrame(QC.camhandle);
            t1=now;
            
            QC.time_start_delta=t1-t0;
            
            if ret==hex2dec('2001') % "QHYCCD_READ_DIRECTLY". No idea but
                                    %   it is like that in the demoes
                pause(0.1)
            end

            success=(ret~=hex2dec('FFFFFFFF'));

            QC.setLastError(success,'could not start single exposure');

            if success
                QC.time_start=t0;
                QC.lastExpTime=QC.ExpTime;
                QC.CamStatus='exposing';
            else
                QC.time_start=NaN;
                QC.lastExpTime=NaN;
                QC.CamStatus='unknown';
                QC.deallocate_image_buffer
            end
        otherwise
            QC.deallocate_image_buffer
            QC.lastError='camera not ready to start exposure';
    end

end
