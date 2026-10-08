function img=collectLiveExposure(QC,varargin)
% collect a frame from an ongoing live take, but only if we are in Live Mode, if
%  exposure was started, and time out if waiting for more than X*texp
% NB: according to my experiments with SDK 25.6.16.15, Live mode appears to
%     fail with all ROIs which do not end at y2 = physical_size.ny 
 
    % 600msec is for 16bit, USB3, full frame. If there would be a neat
    %  way of understanding ROI, bit mode, color mode, USB speed, without
    %  wasting time, we could be more strict
    % setting up the scenes for the first image requires additional ~2 secs 
    %  plus about two exposures. Thus for long exposures the first image 
    %  may be retrieved only after something like 3*texp!
    % This is reduced to *one* wasted exposure, thanks to
    %  SetQHYCCDBurstModePatchNumber(QC.camhandle,32001) (see also comments
    %  inside .initStreamMode)
    try
        exptime=double(QC.PreciseExposureInfo.ActualExposureTime)*1e-6;
        % can be 0 if the camera disconnected
    catch
        % for older SDKs which might miss GetQHCCDPreciseExposureInfo
        exptime=QC.ExpTime; % read it only once, via GetQHYCCDParam
            % (beware: could be MAXINT/1e6 if camera went fishing)
    end
    if ~isempty(QC.LastError)
        QC.reportError('invalid exposure time read -- camera disconnected?')
        timeout=0; % elegant way of saying fuck you
    elseif QC.ProgressiveFrame==0
        timeout=max(2*exptime+4, 2.6); % in secs
    else
        timeout=max(exptime+1, 0.6); % not getting an image ontime is anyway suspicious,
                   % don't get stuck forever polling in the called back collector
    end
    
    switch QC.CamStatus
        case {'exposing','reading'}  % check what is set as status in Live
            t0=now;
            ret=-1;
            QC.reportDebug('entering GetQHYCCDLiveFrame polling loop\n')
            if isa(QC.pImg,'POSIXipc.shm')
                pointer=QC.pImg(QC.RingBufferIndex).Pointer;
            else
                pointer=QC.pImg;
            end
            lastTimeBeforeFrameReady=now;
            while ret~=0 && (now-t0)*86400<timeout
                [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,pointer);
                % we have no way at the moment of knowing the real start time
                %  of each usable exposure. This is an estimate, counting
                %  on that the expoure started ExpTime before it is ready
                %  for retrieval. The value is updated at each polling
                %  iteration.
                % According to Ron, a call to GetQHYCCDLiveFrame takes
                %  13ms. Surprisingly, this time would be the same regardless
                %  that ret is -1 (no image yet) or 0. That is, it is not
                %  clear at all when the image download, which may take
                %  ~200ms for a 16bit 9600*6422px image on USB3, takes
                %  place. Possibly, the SDK has already transferred it in
                %  memory by itself into a private buffer, and GetQHYCCDLiveFrame
                %  copies the data to an user accessible buffer with
                %  memcopy(), which is considerably faster than the
                %  transfer.
                % Turning on debug (.Verbose=2), I **do** see ~200ms
                %  differences between the last ret=FFFFFFF and ret=0
                QC.reportDebug('%8s at t=%f\n',dec2hex(ret), toc)
                if ret~=0
                    lastTimeBeforeFrameReady=now;
                    pause(0.001)
                end
            end
            if ret==0
                % According to Ron's experimental results, **for the QHY600**:
                %  * +7ms is added as a median duration of the polling cycle
                %  * we should subtract 205ms to lastTimeBeforeFrameReady,
                %    which results from a regression of data measured using
                %    the internal Pin3 trigger of the QHY600. This might be
                %    the USB transfer time
                %  * for the j-th row, we should add j*46us, accounting for
                %    the rolling shutter offset.
                % To keep compatibility with all the images recorded before
                %  October 2026, we *do not* apply the last two corrections
                %  here. Rather, we will consider them in postprocessing in
                %  pipeline v1.
                QC.TimeStart=lastTimeBeforeFrameReady+(0.007-exptime)/86400;
                QC.TimeEnd=lastTimeBeforeFrameReady+0.007/86400;
                QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                    % even if a subsequent
                                                    % exposure is started
                QC.ProgressiveFrame = QC.ProgressiveFrame+1;
                QC.reportDebug('got image at time %f\n',toc)

                img=unpackImgBuffer(pointer,w,h,channels,bp);
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
    % unitCS.treatNewImage enqueues the current index in the header,
    %  increase it after that
    QC.RingBufferIndex = mod(QC.RingBufferIndex,QC.SharedRingBufferDim)+1;

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