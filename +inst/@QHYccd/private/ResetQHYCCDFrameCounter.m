function ret = ResetQHYCCDFrameCounter(camhandle)
% undocumented, guessed
  ret=calllib('libqhyccd','ResetQHYCCDFrameCounter',camhandle);