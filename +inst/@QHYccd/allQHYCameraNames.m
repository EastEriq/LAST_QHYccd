function names=allQHYCameraNames(Q)
% get the vector of names of all QHY cameras connected to the host computer.
% Because of known limitatins of the SDK, this is done by getting first the
%  number of cameras connected, then connecting individually to each one,
%  closing the connection afterwards. Pay attention that, because of the
%  SDK too, this method has to be called when no connection with any camera
%  is already open, otherwise the camera becames unreachable after the
%  first call to ScanQHYCCD.
% For convenience and integration with the existing codebase, this function
%  is implemented as a method of class QHYccd. In other words, the suggested
%  calling sequence in a matlab session is:
%
% -create a QHYccd object, but DON'T connect to it
% -call this method to get the list of camera names
% -find the numbers of the elements of this list corresponding to the 
%  cameras to be opened
% -call connect() with the first of these indices
% -create more QHYccd objects if it is intended to use more than one
%  camera, and connect each object to its respective number
    num=ScanQHYCCD;
    names=cell(num,1);
    for i=1:num
        Q.connect(i);
        names{i}=Q.CameraName;
        Q.disconnect;
    end
    