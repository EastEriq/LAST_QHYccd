function ret = SetQHYCCDSingleFrameTimeOut(camhandle,timeout)
  ret=calllib('libqhyccd','SetQHYCCDSingleFrameTimeOut',camhandle,timeout);