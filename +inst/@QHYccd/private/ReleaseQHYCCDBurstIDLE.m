function ret = ReleaseQHYCCDBurstIDLE(camhandle)
% undocumented, guessed
  ret=calllib('libqhyccd','ReleaseQHYCCDBurstIDLE',camhandle);