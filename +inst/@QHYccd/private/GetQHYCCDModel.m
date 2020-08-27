function [ret,model]=GetQHYCCDModel(id)
% undocumented, guessed
    Pid=libpointer('cstring',id);
    Pmod=libpointer('cstring',char(65*ones(1,32)));
    [ret,~,model]=calllib('libqhyccd','GetQHYCCDModel',Pid,Pmod);
