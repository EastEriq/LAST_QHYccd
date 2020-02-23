function WaitForIdle(QC,timeout)
% supposed to be a blocking function
% writing this only because I'm asked for. For the QHY it doesn't make
%  too much sense because the camera status is guessed and maintained as
%  class state variables, not read querying the camera. For other cameras
%  it could make sense. The QHY does not return to idle by itself, they do
%  only after reading or aborting exposure

    % placeholder
    if ~exist('timeout','var')
        timeout=1;
    end

    pause(timeout)

end