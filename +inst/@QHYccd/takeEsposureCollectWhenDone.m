function takeEsposureCollectWhenDone(QC,expTime)
% like takeExposure, but in addition starts a timer, 
%  which collects the image behind the scenes when expTime is past.
% The resulting image goes in QC.lastImage
        if exist('expTime','var')
            QC.ExpTime=expTime;
        end
        
        % last image: empty it when starting, or really keep the last
        % one available till a new is there?
        QC.lastImage=[];
        
        QC.takeExposure(expTime)
        
        % tricky - in which context runs the timer? What object is QC?
        %  would it be possible that the timer object belongs to the class?
        collector=timer('ExecutionMode','SingleShot','BusyMode','Queue',...
            'StartDelay',QC.ExpTime,...
            'TimerFcn', 'QC.lastImage=collectExposure(QC);',...
            'StopFcn','@(mTimer,~)delete(mTimer)');
            
        start(collector)
        
        % how to auto-delete(collector)?
end