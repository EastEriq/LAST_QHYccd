function img=collectLiveExposure(QC,varargin)
% collect a frame from an ongoing live take, but only if we are in Live Mode, if
%  exposure was started, and time out if waiting for more than X*texp
 
    % 600msec is for 16bit, USB3, full frame. If there would be a neat
    %  way of understanding ROI, bit mode, color mode, USB speed, without
    %  wasting time, we could be more strict
    % setting up the scenes for the first image requires additional ~2 secs 
    %  plus about two exposures. Thus for long exposures the first image 
    %  may be retrieved only after something like 3*texp!
    exptime=QC.ExpTime; % read it only once, via GetQHYCCDParam
                        % (beware: could be MAXINT/1e6 if camera went fishing)
    if exptime==(2^32-1)*1e-6
        QC.reportError('invalid exposure time read -- camera disconnected?')
        timeout=0; % elegant way of saying fuck you
    elseif QC.ProgressiveFrame==0
        timeout=max(2*exptime+4, 2.6); % in secs
    else
        timeout=5; % not getting an image ontime is anyway suspicious,
                   % don't get stuck forever polling in the called back collector
    end
    
    switch QC.CamStatus
        case {'exposing','reading'}  % check what is set as status in Live
            t0=now;
            ret=-1;
            QC.reportDebug('entering GetQHYCCDLiveFrame polling loop\n')
            while ret~=0 && (now-t0)*86400<timeout
                [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
                % we have no way at the moment of knowing the real start time
                %  of each usable exposure. This is an estimate, counting
                %  on that the expoure started ExpTime before it is ready
                %  for retrieval. The value is updated at each polling
                %  iteration.
                QC.TimeStart=now-exptime/86400;
                QC.reportDebug('%s at t=%f\n',dec2hex(ret), toc)
                if ret~=0
                    pause(0.01)
                end
            end
            if ret==0
                QC.TimeEnd=now;
                QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                    % even if a subsequent
                                                    % exposure is started
                QC.ProgressiveFrame=QC.ProgressiveFrame+1;
                QC.reportDebug('got image at time %f\n',toc)

                img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
                QC.reportDebug('t after unpacking: %f\n',toc)
            else
                img=[];
                QC.TimeEnd=[];
                QC.reportError('timed out without reading a Live image, aborting Live!');
            end
        otherwise
            img=[];
            QC.TimeEnd=[];
            QC.reportError('no image to read because exposure not started');
    end
    QC.LastImageSaved=false;
    QC.LastImage=img;

    if isempty(QC.TimeEnd)
        % try anyway to stop acquisition. Using the stop method of the
        %  timer may fail to execute (callback starving? Deadlock?)
        ret=StopQHYCCDLive(QC.camhandle);
        QC.reportDebug('  stopped live acquisition with code %d\n',ret)
        % if this function was called back by an image collector timer
        %  (i.e. if acquisition was started by QC.takeLive), and something
        %  went wrong, try to stop that timer. We have not assigned it
        %  to a property, hence try to discover it with timerfind
        collector=timerfind('Name',...
            sprintf('ImageCollector-%d',QC.CameraNum));
        QC.reportDebug('  attempting to stop live collector\n')
        stop(collector)
        % the timer deletes itself with its stop function.
    end

    if ~isempty(QC.ImageHandler)
        QC.ImageHandler(QC,varargin{:})
    end

end