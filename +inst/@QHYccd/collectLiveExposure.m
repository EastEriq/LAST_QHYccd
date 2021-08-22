function img=collectLiveExposure(QC,varargin)
% collect a frame from an ongoing live take, but only if we are in Live Mode, if
%  exposure was started, and time out if waiting for more than X*texp
 
    % 600msec is for 16bit, USB3, full frame. If there would be a neat
    %  way of understanding ROI, bit mode, color mode, USB speed, without
    %  wasting time, we could be more strict
    % setting up the scenes for the first image requires additional ~2 secs 
    %  plus about two exposures. Thus for long exposures the first image 
    %  may be retrieved only after something like 3*texp!
    timeout=max(4*QC.ExpTime+3, 2.6); % in secs
    
    switch QC.CamStatus
        case {'exposing','reading'}  % check what is set as status in Live
            t0=now;
            ret=-1;
            while ret~=0 && (now-t0)*86400<timeout
                [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
                pause(0.01)
                if QC.Verbose>1
                    fprintf('%s at t=%f\n',dec2hex(ret), toc)
                end
                % we have no way at the moment of knowing the real start time
                %  of each usable exposure. This is an estimate, counting
                %  on that the expoure started ExpTime before it is ready
                %  for retrieval. The value is updated at each polling
                %  iteration.
                QC.TimeStart=now-QC.ExpTime/86400;
            end
            if ret==0
                QC.TimeStartLastImage=QC.TimeStart; % so we know when QC.LastImage was started,
                                                    % even if a subsequent
                                                    % exposure is started
                QC.TimeEnd=now;
                QC.ProgressiveFrame=QC.ProgressiveFrame+1;
                if QC.Verbose>1
                    fprintf('got image at time %f\n',toc);
                end
                img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
                if QC.Verbose>1
                    fprintf('t after unpacking: %f\n',toc);
                end
            else
                img=[];
                QC.TimeEnd=[];
                QC.LastError='timed out without reading a Live image!';
                QC.report([QC.LastError,'\n']);
            end
        otherwise
            QC.TimeEnd=[];
            QC.LastError='no image to read because exposure not started';
            img=[];
    end
    QC.LastImage=img;
    QC.LastImageSaved=false;

    if ~isempty(QC.ImageHandler)
        QC.ImageHandler(QC,varargin{:})
    end

end