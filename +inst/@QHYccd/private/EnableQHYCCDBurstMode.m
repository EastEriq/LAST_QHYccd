function [ret]=EnableQHYCCDBurstMode(camhandle,mode)
% undocumented, guessed
    ret=calllib('libqhyccd','EnableQHYCCDBurstMode',camhandle,mode);
