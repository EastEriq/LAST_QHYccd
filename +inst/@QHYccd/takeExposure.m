function takeExposure(QC,expTime)
% set up the scenes for taking a single exposure

    if exist('expTime','var')
        QC.ExpTime=expTime;
    end
    
    QC.progressive_frame=0;

    QC.allocate_image_buffer

    SetQHYCCDStreamMode(QC.camhandle,0);

    ret=ExpQHYCCDSingleFrame(QC.camhandle);
    if ret==hex2dec('2001') % "QHYCCD_READ_DIRECTLY". No idea but
                            %   it is like that in the demoes
        pause(0.1)
    end

    QC.setLastError(ret==0,'could not start single exposure');

end
