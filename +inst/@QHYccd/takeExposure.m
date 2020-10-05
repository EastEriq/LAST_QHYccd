function takeExposure(QC,expTime)
% like startExposure+collectExposure, but the latter is called by a timer, 
%  which collects the image behind the scenes when expTime is past.
% The resulting image goes in QC.LastImage
        if exist('expTime','var')
            QC.ExpTime=expTime;
        end
        
        % last image: empty it when starting, or really keep the last
        % one available till a new is there?
        QC.LastImage=[];
        
        QC.startExposure(QC.ExpTime)
        
        collector=timer('Name','ImageCollector',...
            'ExecutionMode','SingleShot','BusyMode','Queue',...
            'StartDelay',QC.ExpTime,...
            'TimerFcn',@(~,~)collectExposure(QC),...
            'StopFcn',@(mTimer,~)delete(mTimer));
            
        start(collector)
        
end
