function success=connect(QC,cameranum)
    % Open the connection with a specific camera, and
    %  read from it some basic information like color capability,
    %  physical dimensions, etc.
    %  cameranum: int, number of the camera to open (as enumerated by the SDK)
    %     May be omitted. In that case the first camera is referred to
    % WARNING: reconnecting a camera object which was previously
    %          disconnected (but not destroyed) crashes Matlab, as of now
    %          (27/8/2020)

    QC.lastError='';
    
    if ~exist('cameranum','var')
        QC.cameranum=1; % open the first camera. It would be nice if there
                        %  was a way to check which other cameras are
                        %  open, and open the next
    else
        QC.cameranum=cameranum;
    end
    [ret,QC.CameraName]=GetQHYCCDId(max(QC.cameranum-1,0));

    if ret
        QC.lastError=sprintf('could get name of camera #%d',QC.cameranum);
        QC.report([QC.lastError '\n'])
        return;
    end
    
    QC.camhandle=OpenQHYCCD(QC.CameraName);
    if ~isNull(QC.camhandle)
        QC.report(sprintf('Opened camera "%s"\n',QC.CameraName));
    else
        QC.lastError=sprintf('could not open camera #%d',QC.cameranum);
        QC.report([QC.lastError '\n'])
    end
    
    InitQHYCCD(QC.camhandle) % this one crashes when reconnecting!

    % query the camera and populate the QC structures with some
    %  characteristic values

    [ret1,QC.physical_size.chipw,QC.physical_size.chiph,...
        QC.physical_size.nx,QC.physical_size.ny,...
        QC.physical_size.pixelw,QC.physical_size.pixelh,...
                 bp_supported]=GetQHYCCDChipInfo(QC.camhandle);

    [ret2,QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
        QC.effective_area.sxEff,QC.effective_area.syEff]=...
                 GetQHYCCDEffectiveArea(QC.camhandle);

    % warning: this returns strange numbers, which at some point
    %  I've also seen to change (maybe depending on other calls'
    %  order?)
    [ret3,QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
        QC.overscan_area.sxOver,QC.overscan_area.syOver]=...
                      GetQHYCCDOverScanArea(QC.camhandle);

    ret4=IsQHYCCDControlAvailable(QC.camhandle, inst.qhyccdControl.CAM_COLOR);
    colorAvailable=(ret4>0 & ret4<5);

    QC.report(sprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
        QC.physical_size.chipw,QC.physical_size.chiph,...
        QC.physical_size.nx,QC.physical_size.ny,...
        QC.physical_size.pixelw,QC.physical_size.pixelh,...
        bp_supported))
    QC.report(sprintf(' effective chip area: (%d,%d)+(%dx%d)\n',...
        QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
        QC.effective_area.sxEff,QC.effective_area.syEff));
    QC.report(sprintf(' overscan area: (%d,%d)+(%dx%d)\n',...
        QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
        QC.overscan_area.sxOver,QC.overscan_area.syOver));
    if colorAvailable, QC.report(' Color camera\n'); end

    [ret5,Nmodes]=GetQHYCCDNumberOfReadModes(QC.camhandle);
    if QC.verbose, QC.report('Read modes:\n'); end
    for mode=1:Nmodes
        [~,QC.readModesList(mode).name]=...
            GetQHYCCDReadModeName(QC.camhandle,mode-1);
        [~,QC.readModesList(mode).resx,QC.readModesList(mode).resy]=...
            GetQHYCCDReadModeResolution(QC.camhandle,mode-1);
        QC.report(sprintf('(%d) %s: %dx%d\n',mode-1,QC.readModesList(mode).name,...
            QC.readModesList(mode).resx,QC.readModesList(mode).resy));
    end

    success = (ret1==0 & ret2==0 & ret3==0);
    
    % TODO perhaps improve granularity of this report
    QC.setLastError(success,'something went wrong when initializing the camera');

    % put here also some plausible parameter settings which are
    %  not likely to be changed

    QC.offset=0;
    colormode=false; % (local variable because no getter)
    QC.color=colormode;

    % USBtraffic value is said to affect glow. 30 is the value
    %   normally found in demos, it may need to be changed, also
    %   depending on USB2/3
    % The SDK manual says:
    %  Used to set camera traffic,the bandwidth setting is only valid
    %  for continuous mode, and the larger the bandwidth setting, the
    %  lower the frame rate, which can reduce the load of the
    %  computer.
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC,3);

    % from https://www.qhyccd.com/bbs/index.php?topic=6861
    %  this is said to affect speed, and accepting 0,1,2
    % The SDK manual says:
    %  USB transfer speed,but part of cameras not support
    %  this function.
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_SPEED,2);

    % set full area as ROI (?) -- wishful
    if colormode
        QC.ROI=[0,0,QC.physical_size.nx,QC.physical_size.ny];
    else
        % this is problematic in color mode
        SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
        QC.ROI=[QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                QC.effective_area.x1Eff+QC.effective_area.sxEff,...
                QC.effective_area.y1Eff+QC.effective_area.syEff];
    end
    
    % set default values, perhaps differentiating camera models
    QC.default_values

    QC.CamStatus='idle'; % whishful, if we got till here.
    
end
