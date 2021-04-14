Q=inst.QHYccd;
Q.connect;
Q.verbose=2;
%Q.DebugOutput=true;

Q.disconnect

% try also clear all

fprintf('Now disconnect the power of the camera....\n')

% I've observed crashes, but?