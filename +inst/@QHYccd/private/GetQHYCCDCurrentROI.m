function [ret,startX,startY,sizeX,sizeY]=GetQHYCCDCurrentROI(camhandle)
% undocumented, guessed
    PstartX=libpointer('uint32Ptr',0);
    PstartY=libpointer('uint32Ptr',0);
    PsizeX=libpointer('uint32Ptr',0);
    PsizeY=libpointer('uint32Ptr',0);
    [ret,~,startX,startY,sizeX,sizeY]=calllib('libqhyccd','GetQHYCCDCurrentROI',...
                                             camhandle,PstartX,PstartY,PsizeX,PsizeY);
