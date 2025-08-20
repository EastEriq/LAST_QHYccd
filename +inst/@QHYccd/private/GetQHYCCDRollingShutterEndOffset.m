function [ret,offset] = GetQHYCCDRollingShutterEndOffset(camhandle,row)
    Poffset=libpointer('doublePtr',0);
    [ret,~,offset] = calllib('libqhyccd','GetQHYCCDRollingShutterEndOffset',...
                                          camhandle,uint32(row),Poffset);