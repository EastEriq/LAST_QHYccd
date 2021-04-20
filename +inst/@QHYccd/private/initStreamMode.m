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

    if newmode==1 && QC.StreamMode~=1
        if contains(QC.CameraName,'QHY600')
            ret=SetQHYCCDStreamMode(QC.camhandle,1);
            if QC.verbose>1
                fprintf('t after SetQHYCCDStreamMode: %f\n',toc);
            end
            InitQHYCCD(QC.camhandle);
            if QC.verbose>1
                fprintf('t after InitQHYCCD: %f\n',toc);
            end
            % set again parameters here
            QC.resetCriticalParameters
        else
            InitQHYCCD(QC.camhandle);
            % set again parameters here
            QC.resetCriticalParameters
            ret=SetQHYCCDStreamMode(QC.camhandle,1);
        end

        if ret==0
            % The most fantastic call to avoid (??) a queue of two
            %  exposures in the DDR before a third can be retrieved.
            % From an email of Qiu Hongyun, 20/4/2021
            SetQHYCCDBurstModePatchNumber(QC.camhandle,32001);
            QC.StreamMode=1;
        else
            QC.report(ret,'Camera cannot be put in Live mode')
            QC.LastError='Camera cannot be put in Live mode';
            return
        end
    else % this includes Streammode==[] and 0
        if newmode~=1 && QC.StreamMode~=0
            InitQHYCCD(QC.camhandle);
            % set again parameters here
            QC.resetCriticalParameters
            SetQHYCCDStreamMode(QC.camhandle,0);
            if QC.verbose>1
                fprintf('t after SetQHYCCDStreamMode: %f\n',toc);
            end
            QC.StreamMode=0;
        end
    end
