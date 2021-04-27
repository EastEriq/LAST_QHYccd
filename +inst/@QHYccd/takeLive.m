function takeLive(QC,num,expTime,varargin)
% Take a series of num images with the same exposure time,
%  setting the camera in Live mode. This is a non-blocking function,
%  which uses a timer callback function to retrieve the images.
% Images are handled as soon as they are retrieved by the user function defined
% in the object property Q.ImageHandler. The function assigned there
%  receives the whole object Q as first argument, and transparently
%  any other further argument added to the call of 
%    Q.takeLive(num,expTime,extra_args)
%
%  See the function simpleshowimage(Q,varargin) for an example:
%
%    Q.ImageHandler=@simpleshowimage
%    Q.takeLiveSeq(4,0.5,'retrieved at t=')
%
% Transitioning from Single Frame to Live Mode takes some seconds
%  of initialization time, which are spent the first time this
%  method is called. To do it preemptively without really acquiring
%  images, call Q.takeLiveSeq(0).

    if exist('expTime','var')
        QC.ExpTime=expTime;
    end

    startLive(QC)
    deltat=QC.TimeStartDelta*86400; % TimeStartDelta set inside startLive
    if ~isempty(QC.LastError)
        return
    end
    
    collector=timer('Name',sprintf('ImageCollector-%d',QC.CameraNum),...
        'ExecutionMode','fixedRate','BusyMode','Queue',...
        'TasksToExecute',num,'Period',QC.ExpTime,...
        'TimerFcn',@(~,~)collectLiveExposure(QC,varargin{:}),...
        'StopFcn',@(mTimer,~)stoplive(QC,mTimer));
    
    
    % StartDelay should be decreased to 1*ExpTime if some fantastic
    %  patch code for retrieving the first image available is someday
    %  revealed!
    collector.StartDelay=max(round(2*QC.ExpTime-deltat,3),0);
    
    start(collector)
    
    function stoplive(QC,mTimer)
        StopQHYCCDLive(QC.camhandle);
        delete(mTimer);
    end
end
