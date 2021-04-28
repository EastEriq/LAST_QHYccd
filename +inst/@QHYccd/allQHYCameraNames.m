function names=allQHYCameraNames(Q)
% get the vector of names of all QHY cameras connected to the host computer.
%
% For convenience and integration with the existing codebase, this function
%  is implemented as a method of class QHYccd. In other words, the suggested
%  calling sequence in a matlab session is:
%
% -create a QHYccd object, doesn't matter whether we connect to the camera
% -call this method to get the list of camera names
% -find the numbers of the elements of this list corresponding to the 
%  cameras to be opened
% -call connect() with the first of these indices
% -create more QHYccd objects if it is intended to use more than one
%  camera, and connect each object to its respective number
    num=ScanQHYCCD;
    names=cell(num,1);
    for i=1:num
        [~,names{i}]=GetQHYCCDId(i-1);
    end
    