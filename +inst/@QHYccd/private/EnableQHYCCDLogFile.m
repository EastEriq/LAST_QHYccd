function EnableQHYCCDLogFile(enable)
% argument is true or false
%  Now I tried it with the current 'stable' sdk, i.e. 21.7.16.
% The moment it is turned on, it tries apparently to write into
%  a file .qhyccd/qhyccd.log . However:
%  - if the directory .qhyccd/ doesn't exist, it creates it anew, but with
%     mode dr----x--t: the userspace process cannot then write a file
%     there, and stderr reports 
%      "feiled /home/last04/ocs/.qhyccd/qhyccd.log" at every blabber line
%      (here matlab pwd was /home/last04/ocs/)
%  - if the directory .qhyccd/ exists, an empty file qhyccd.log is
%    created, and at the first call generating blabber, matlab silently
%    segfaults
    calllib('libqhyccd','EnableQHYCCDLogFile',enable);