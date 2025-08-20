function [ret,name]=GetQHYCCDSensorName(camhandle,mode)
% undocumented, guessed
    Pname=libpointer('cstring',char(65*ones(1,32)));
    [ret,~,name]=calllib('libqhyccd','GetQHYCCDSensorName',...
                                             camhandle,mode,Pname);
