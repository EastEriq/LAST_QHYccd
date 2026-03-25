function reportFPS(Q,varargin)
% sample handler function for computing FPS of live takes (as a function,
% e.g., of USBtraffic, SaveOnDisk, ComputeFWHM, etc.)
% i.e., set  Q.ImageHandler = @Q.reportFPS;
    if Q.ProgressiveFrame==1
       Q.UserData=struct('Start',Q.TimeStart,'Previous',Q.TimeStart);
    else
       fprintf('dt since last frame = %.1fms\n',...
           (Q.TimeStart-Q.UserData.Previous)*86400000)
       Q.UserData.Previous=Q.TimeStart;
    end
    if Q.ProgressiveFrame==Q.SequenceLength
       FPS=double(Q.SequenceLength-1)/((Q.TimeStart-Q.UserData.Start)*86400);
       fprintf('mean dt = %.1fms, mean FPS = %.3f\n', 1000/FPS, FPS)
    end