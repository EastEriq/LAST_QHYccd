function startExposure(QC,expTime)
% set up the scenes for taking a single exposure

    switch QC.CamStatus
        case {'idle','unknown'} % shall we try exposing for 'unknown' too?
            if exist('expTime','var')
                QC.ExpTime=expTime;
            end

            QC.progressive_frame=0;

            if QC.verbose>1
                tic;
            end
            QC.allocate_image_buffer
            if QC.verbose>1
                fprintf('t after allocating buffer: %f\n',toc);
            end

           SetQHYCCDStreamMode(QC.camhandle,0);
           if QC.verbose>1
               fprintf('t after SetQHYCCDStreamMode: %f\n',toc);
           end
           
            t0=now;
            ret=ExpQHYCCDSingleFrame(QC.camhandle);
            if QC.verbose>1
                fprintf('t after ExpQHYCCDSingleFrame: %f\n',toc);
            end
            t1=now;
            
            QC.TimeStartDelta=t1-t0;
            
            if ret==hex2dec('2001') % "QHYCCD_READ_DIRECTLY". No idea but
                                    %   it is like that in the demoes
                pause(0.1)
            end

            success=(ret~=hex2dec('FFFFFFFF'));

            QC.setLastError(success,'could not start single exposure');

            if success
                QC.TimeStart=t0;
                QC.lastExpTime=QC.ExpTime;
                QC.CamStatus='exposing';
            else
                QC.TimeStart=NaN;
                QC.lastExpTime=NaN;
                QC.CamStatus='unknown';
                QC.deallocate_image_buffer
            end
        otherwise
            QC.deallocate_image_buffer
            QC.LastError='camera not ready to start exposure';
    end

end
