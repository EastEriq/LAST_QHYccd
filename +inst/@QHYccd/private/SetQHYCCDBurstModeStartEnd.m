function ret = SetQHYCCDBurstModeStartEnd(camhandle,burststart,burstend)
% undocumented, guessed
  ret=calllib('libqhyccd','SetQHYCCDBurstModeStartEnd',camhandle,...
              uint16(burststart),uint16(burstend));