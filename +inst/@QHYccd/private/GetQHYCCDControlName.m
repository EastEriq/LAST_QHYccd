function [ret,name]=GetQHYCCDControlName(camhandle,controlId)
% undocumented, guessed
    Pname=libpointer('cstring',char(zeros(1,32)));
    [ret,~,name]=calllib('libqhyccd','GetQHYCCDControlName',camhandle,...
                                      uint16(controlId),Pname);
