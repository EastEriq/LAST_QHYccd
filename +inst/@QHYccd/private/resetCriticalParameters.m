function resetCriticalParameters(QC)
% set again parameters whic must be resetted when changing StreamMode
%  otherwise evil things happens
    QC.Color=false;
    QC.Binning=QC.Binning;
    SetQHYCCDResolution(QC.camhandle,0,0,QC.physical_size.nx,QC.physical_size.ny);
    QC.BitDepth=16;
    QC.Gain=QC.Gain; % maybe this has to be reset, maybe not
    QC.Offset=QC.Offset; % ditto
    % maybe too low USB traffic is at risk od libusb errors -> crashes
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC,10);
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_DDR,1);
