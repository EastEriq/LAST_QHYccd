function EnableQHYCCDLogFile(level)
% level is declared as integer
    calllib('libqhyccd','SetQHYCCDLogLevel',level);