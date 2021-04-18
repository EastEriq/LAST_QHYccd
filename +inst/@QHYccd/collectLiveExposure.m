function img=collectLiveExposure(QC,w,h,bp,channels)
% collect a frame from an ongoing live take, but only if we are in Live Mode, if
%  exposure was started, and time out if waiting for more than texp
 

    % 600msec is for 16bit, USB3, full frame. If there would be a neat
    %  way of understanding ROI, bit mode, color mode, USB speed, without
    %  wasting time, we could be more strict 
    timeout=max(1.5*QC.ExpTime,0.6); % in secs
    
    GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC)
    [ret,minp,maxp,stepp]=...
        GetQHYCCDParamMinMaxStep(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC)
    
    switch QC.CamStatus
        case {'exposing','reading'}  % check what is set as status in Live
            t0=now;
            ret=-1;
            while ret~=0 && (now-t0)*86400<timeout
                [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
                pause(0.1)
                if QC.verbose>1
                    fprintf('%s\n',dec2hex(ret))
                end
            end
            if ret~=-1
                if QC.verbose>1
                    fprintf('got image at time %f\n',toc);
                end
                
                img=unpackImgBuffer(QC.pImg,w,h,channels,bp);
                if QC.verbose>1
                    fprintf('t after unpacking: %f\n',toc);
                end
            else
                QC.LastError='timed out without reading a Live image!';
                QC.report(QC.LastError);
            end
        otherwise
            QC.LastError='no image to read because exposure not started';
            img=[];
    end
end