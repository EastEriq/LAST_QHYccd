function resetCriticalParameters(QC)
% set again parameters which must be resetted when changing StreamMode
%  otherwise evil things happens
% As some of these parameters (e.g color, ROI) have a setter function in 
%  the SDK but not a getter, for now I set them the way we are most likely
%  to use them. Future handling of different values will probably require
%  a representation of the last set status in the class itself, with design
%  complications.
    QC.Color=false;
    QC.Binning=QC.Binning;
    QC.reportDebug('calling SetQHYCCDResolution\n')
    SetQHYCCDResolution(QC.camhandle,0,0,QC.physical_size.nx,QC.physical_size.ny);
    QC.reportDebug('after SetQHYCCDResolution call\n')
%     QC.ROI=[QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
%         QC.effective_area.x1Eff+QC.effective_area.sxEff,...
%         QC.effective_area.y1Eff+QC.effective_area.syEff];
    QC.BitDepth=16;
    % resetting Gain this way is ok for the QHY600, not for the 367 which
    %  instead changes it to Gain=2000
    QC.Gain=QC.Gain;
    QC.Offset=QC.Offset; % maybe this has to be reset, maybe not
    % maybe too low USB traffic is at risk od libusb errors -> crashes
    QC.reportDebug('calling SetQHYCCDParam USBTRAFFIC & DDR\n')
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC,10);
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_DDR,1);
    QC.reportDebug('after SetQHYCCDParam USBTRAFFIC & DDR\n')

    
    % and let's hope that I haven't forgotten any other essential setting.
    % Other settings (e.g. temperature) might just survive mode change...
