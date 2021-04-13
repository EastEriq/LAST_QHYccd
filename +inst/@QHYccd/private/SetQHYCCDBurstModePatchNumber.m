function ret = SetQHYCCDBurstModePatchNumber(camhandle,value)
% undocumented, guessed
  ret=calllib('libqhyccd','SetQHYCCDBurstModePatchNumber',camhandle,value);