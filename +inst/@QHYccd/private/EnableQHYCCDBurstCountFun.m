function ret = EnableQHYCCDBurstCountFun(camhandle,count)
% undocumented, guessed
  ret=calllib('libqhyccd','EnableQHYCCDBurstCountFun',camhandle,count);