function [ret,model]=GetQHYCCDModel(id)
% undocumented, guessed
% don't call with id=[] - it immediately segfaults
    if isempty(id)
        id='';
    end
    Pid=libpointer('cstring',id);
    Pmod=libpointer('cstring','');
    [ret,~,model]=calllib('libqhyccd','GetQHYCCDModel',Pid,Pmod);
