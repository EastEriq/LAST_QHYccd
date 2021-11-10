function initStreamMode(QC,newmode)
% call InitQHYCCD() stetting the desired Stream mode (Single frame or Live)
%  Depending on the StreamMode and the camera model, the sequence of calls
%  has to be different.
% Reinitialization is mandatory when changing Stream Mode. Otherwise,
%  bad things happen: corrupted images, or, ordinarily, all possible
%  crashes.
    if isempty(QC.StreamMode)
        QC.StreamMode=-1;
    end

    if ~exist('newmode','var')
        newmode=QC.StreamMode; % i.e. no change
    end

    if newmode ~= QC.StreamMode
        if contains(QC.CameraName,'QHY600')
            ret=SetQHYCCDStreamMode(QC.camhandle,newmode);
            QC.reportDebug('t after SetQHYCCDStreamMode: %f\n',toc)
            InitQHYCCD(QC.camhandle);
            QC.reportDebug('t after InitQHYCCD: %f\n',toc);
        else
            InitQHYCCD(QC.camhandle);
            QC.reportDebug('t after InitQHYCCD: %f\n',toc);
            ret=SetQHYCCDStreamMode(QC.camhandle,newmode);
            QC.reportDebug('t after SetQHYCCDStreamMode: %f\n',toc);
        end
        if newmode==1 && ret==0
            % The most fantastic call to avoid (??) a queue of two
            %  exposures in the DDR before a third can be retrieved.
            %  This BurstModePatch reduces it to one (not zero, unfortunately)
            % From an email of Qiu Hongyun, 20/4/2021
            SetQHYCCDBurstModePatchNumber(QC.camhandle,32001);
            QC.StreamMode=1;
        elseif newmode==1 && ret==0
            QC.reportError('Camera cannot be put in Live mode')
            QC.StreamMode=0;
            return
        else
            QC.StreamMode=0;            
        end
    end
    
    if true %newmode==1
        % set again parameters here. It seems that we have
        %  to redo it before each live sequence, even if we had already
        %  done it earlier and we haven't changed StreamMode. Otherwise,
        %  bad things.
        QC.resetCriticalParameters
    end
