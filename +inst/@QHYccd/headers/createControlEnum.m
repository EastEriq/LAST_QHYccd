% quick & dirty parsing script to parse the qhyccdstruct.h
%  file and generate a matlab enumeration
% Run from this directory
if exist('/usr/lib/x86_64-linux-gnu/libqhyccd.so.6','file')
    % file locations style James Fidell package
    fid1=fopen('/usr/include/qhyccd/qhyccdstruct.h');
elseif exist('/usr/local/lib/libqhyccd.so.20','file')
    % file locations style QHY original install.h
    fid1=fopen('/usr/local/include/qhyccdstruct.h');
else
    error('these QHY installations change all the time; what shall I do?')
end
fid2=fopen('../../qhyccdControl.m','w');


l=''; controlblock=false; inum=-1;
while ischar(l)
    l=fgetl(fid1);
    if ischar(l)
        l=regexprep(l,'/\*[^\*]*\*/',''); %remove comments in v.20.6.23
    end
    if controlblock
        if strfind(l,'}')>0
            controlblock=false;
            fprintf(fid2,'\n    end\nend\n');
        end
        controlword=strrep(strtok(l),',','');
        if ~isempty(controlword) && controlblock
            if inum>=0
                fprintf(fid2,',\n');
            end
            inum=inum+1;
            fprintf(fid2,'        %s (%d)',controlword,inum);
        end
    end
    if strfind(l,'enum CONTROL_ID') % v.6.0.x has "typedef enum CONTROL_ID" here
        controlblock=true;
        fgetl(fid1); % skip {
        fprintf(fid2,'classdef qhyccdControl < uint16\n    enumeration\n');
    end
end
fclose(fid1);
fclose(fid2);
