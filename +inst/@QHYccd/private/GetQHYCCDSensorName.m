function [ret,name]=GetQHYCCDSensorName(camhandle)
    Pname=libpointer('cstring',char(zeros(1,32)));
    [ret,~,name]=calllib('libqhyccd','GetQHYCCDSensorName',...
                                             camhandle,Pname);
