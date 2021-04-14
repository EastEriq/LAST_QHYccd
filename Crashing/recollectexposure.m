Q=inst.QHYccd;
Q.connect;
Q.verbose=2;
Q.DebugOutput=true;

Q.startExposure(1)
Q.collectExposure;
pause(1)
Q.collectExposure;

clear all
fprintf('crash within a few seconds...\n')

% QHYCCD|QHYCCD.CPP|GetQHYCCDSingleFrameInternal| #2 readnum = 1 badframenum = 0 fllagquit = 0
