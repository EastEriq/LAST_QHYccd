function [ret,x1,y1,sx,sy]=GetQHYCCDEffectiveArea(camhandle)

Px1=libpointer('uint32Ptr',0);
Py1=libpointer('uint32Ptr',0);
Psx=libpointer('uint32Ptr',0);
Psy=libpointer('uint32Ptr',0);
[ret,~,x1,y1,sx,sy]=...
    calllib('libqhyccd','GetQHYCCDEffectiveArea',camhandle,Px1,Py1,Psx,Psy);
