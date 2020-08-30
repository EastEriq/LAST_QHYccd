function coolingOff(QC)
% Turn cooling off by commanding PWM to 0
    success=...
        (SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_MANULPWM,0)==0);
    QC.setLastError(success,'could not turn off cooling')

end