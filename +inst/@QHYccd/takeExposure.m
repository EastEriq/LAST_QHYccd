function takeExposure(QC,expTime)
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
            if ret==hex2dec('2001') % "QHYCCD_READ_DIRECTLY". No idea but
                %   it is like that in the demoes
                pause(0.1)
            end

            success=(ret~=hex2dec('FFFF'));

            QC.setLastError(success,'could not start single exposure');

            if success
                QC.t_exposure_started=t0;
                QC.lastExpTime=QC.ExpTime;
                QC.CamStatus='exposing';
            else
                QC.t_exposure_started=NaN;
                QC.lastExpTime=NaN;
                QC.CamStatus='unknown';
                QC.deallocate_image_buffer
            end
        otherwise
            QC.deallocate_image_buffer
            QC.lastError='camera not ready to start exposure';
    end

end
