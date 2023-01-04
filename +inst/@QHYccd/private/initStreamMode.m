function initStreamMode(QC,newmode)
% call InitQHYCCD() stetting the desired Stream mode (Single frame or Live)
%  Depending on the StreamMode and the camera model, the sequence of calls
%  has to be different.
% Reinitialization is mandatory when changing Stream Mode. Otherwise,
%  bad things happen: corrupted images, or, ordinarily, all possible
%  crashes.
% Further problem observed, Live mode sequences with very short exposure
%  time are very problematic if run on two cameras on the same computer
%  simultaneously. In such cases the first acquisition sequence may
%  succeed, but the second one invariably hangs or crashes Matlab. Errors
%  reported involve assertions on __pthread_mutex_lock, on __pthread_tpp_change_priority,
%  and "The futex facility returned an unexpected error code. My
%  speculation is that the SDK is not really thread safe, or that it calls
%  unsafely libusb functions (one of the reports is 
%  "usbi_transfer_get_os_priv: Assertion `transfer->num_iso_packets >= 0'
%  failed"
% After such crashes the cameras are left in an uncommunicable state,
%  restored only by power cycling.
% A workaround for this problem seems to be to always call InitQHYCCD()
%  before live sequences with ExpTime<0.5s. This induces of course an
%  additional initial delay.

    if isempty(QC.StreamMode)
        QC.StreamMode=-1;
    end

    if ~exist('newmode','var')
        newmode=QC.StreamMode; % i.e. no change
    end
    
    if QC.Verbose<=1 % Q&D fix to use toc later on, if tic not called earlier
        tic;
    end
    
    if newmode ~= QC.StreamMode || newmode==1 && QC.ExpTime<0.5
        if newmode==1 && QC.ExpTime<0.5
            % the effectivenes of this is dubious, but is the best
            %  guess so far
            QC.report('calling InitQHYCCD twice, to circumvent deadlock\n')
            QC.report(' with two simultaneous short exposure acquisitions\n')
            expT=QC.ExpTime;
            InitQHYCCD(QC.camhandle);
            QC.ExpTime=expT;
        end
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
        if newmode==1
            if ret==0
                % The most fantastic call to avoid (??) a queue of two
                %  exposures in the DDR before a third can be retrieved.
                %  This BurstModePatch reduces it to one (not zero, unfortunately)
                % From an email of Qiu Hongyun, 20/4/2021
                SetQHYCCDBurstModePatchNumber(QC.camhandle,32001);
                QC.StreamMode=1;
            else
                QC.reportError('Camera cannot be put in Live mode')
                QC.StreamMode=0;
                return
            end
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
