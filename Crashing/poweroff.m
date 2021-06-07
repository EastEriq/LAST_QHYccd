Q=inst.QHYccd;
Q.connect;
Q.Verbose=2;
Q.DebugOutput=true;

% Q.disconnect % if this is uncommented, no crash 
%  (because Q.camhandle becomes [], and hence unloadlibrary is not executed
%   by the delete method, as of now!)

clear Q

if libisloaded('libqhyccd')
    fprintf('libqhyccd is still loaded\n')
end

fprintf('\nNow disconnect the power of the camera.\n')
fprintf('Matlab crashes within a couple of seconds...\n')

% QHYCCD|QHYCCD.CPP|CloseQHYCCD|START
% QHYCCD|QHYCAM.CPP|closeCamera
% QHYCCD|QHY5IIIBASE.CPP|DisConnectCamera|DisConnectCamera
% QHYCCD|QHYCCD.CPP|CloseQHYCCD|END return value=0
% QHYCCD|QHYCCD.CPP|ReleaseQHYCCDResource|START
% QHYCCD|QHYCCD.CPP|ReleaseQHYCCDResource|Warning     should not do ReleaseQHYCCDResource unless you are going to exit the library 
% QHYCCD|QHYCCD.CPP|ReleaseQHYCCDResource| !!!!  Warning skip release due to config force_release = false !!!!
% QHYCCD|QHYCCD.CPP|ReleaseQHYCCDResource| skip ReleaseQHYCCDResource for compatible 


% Stack Trace (from fault):
% [  0] 0x00007f224d7dd40d                                   <unknown-module>+00000000

fprintf('\ninstead, if you don''t power off, matlab crashes after 30 sec\n')