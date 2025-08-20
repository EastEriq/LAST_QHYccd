function [ret,name]=GetQHYCCDSensorName(camhandle)
    Pname=libpointer('cstring',char(65*ones(1,32)));
    [ret,~,name]=calllib('libqhyccd','GetQHYCCDSensorName',...
                                             camhandle,Pname);
