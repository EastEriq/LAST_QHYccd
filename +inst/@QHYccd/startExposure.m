function startExposure(QC,expTime)
% set up the scenes for taking a single exposure

    if isempty(QC.StreamMode) || QC.StreamMode~=0
        % this is expensive (~5sec), but needed if we were previously in
        %  Live mode
        tic
        initStreamMode(QC,0)
    end

    switch QC.CamStatus
        case {'idle','unknown'} % shall we try exposing for 'unknown' too?
            if exist('expTime','var')
                QC.ExpTime=expTime;
            end

            QC.ProgressiveFrame=0;

            if QC.Verbose>1
                tic;
            end
            QC.allocate_image_buffer
            if QC.Verbose>1
                fprintf('t after allocating buffer: %f\n',toc);
            end

            t0=now;
            ret=ExpQHYCCDSingleFrame(QC.camhandle);
            if QC.Verbose>1
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
                % undocumented, I hope it does what it's name says
                %  apparently no timeout on an unpowered QHY367, however
                % SetQHYCCDSingleFrameTimeOut(QC.camhandle,QC.ExpTime*1500)
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
