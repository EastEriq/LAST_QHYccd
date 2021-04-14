function imgs=takeLiveSeq(QC,num,expTime)
% attempting once more to take live images, this time with the SDK 21-02-01
% NOT WORKING, can hang or crash matlab in creative ways, depending on camera (600 or 367,
%  USB port or cable), depending probably on low level USB communication issues, DDR
%  issues, and wrong call sequence of SDK functions.
% Don't use in real life.

    imgs={};

    if QC.verbose>1
        tic;
    end

    if contains(QC.CameraName,'QHY600')
        SetQHYCCDStreamMode(QC.camhandle,1);
        if QC.verbose>1
            fprintf('t after SetQHYCCDStreamMode: %f\n',toc);
        end
        InitQHYCCD(QC.camhandle);
        if QC.verbose>1
            fprintf('t after InitQHYCCD: %f\n',toc);
        end
    else
        InitQHYCCD(QC.camhandle);
        SetQHYCCDStreamMode(QC.camhandle,1);
    end

    % set again parameters here
    
    QC.Color=false;
    QC.Binning=[1 1];
    SetQHYCCDResolution(QC.camhandle,0,0,QC.physical_size.nx,QC.physical_size.ny);
    QC.BitDepth=16;
    QC.Gain=0;
    QC.Offset=1;
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_USBTRAFFIC,30);
    SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_DDR,1);
    if exist('expTime','var')
        QC.ExpTime=expTime;
    end
    if QC.verbose>1
        fprintf('t after setting again parameters: %f\n',toc);
    end

    QC.allocate_image_buffer
    if QC.verbose>1
        fprintf('t after allocating buffer: %f\n',toc);
    end

    BeginQHYCCDLive(QC.camhandle);
    if QC.verbose>1
        fprintf('t after BeginQHYCCDLive: %f\n',toc);
    end

    for i=1:num

        if ~isempty(QC.LastError)
            return
        end
        
        ret=-1;
        while ret~=0
            [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
            pause(0.1)
            fprintf('%s\n',dec2hex(ret))
        end
        if QC.verbose>1
            fprintf('got image %d at time %f\n',i,toc);
        end
        
        imgs{i}=unpackImgBuffer(QC.pImg,w,h,channels,bp);
        
        if ~isempty(QC.LastError)
            return
        end
    end
    
    fprintf('stopping live mode\n')
    StopQHYCCDLive(QC.camhandle);
    if QC.verbose>1
        fprintf('t after StopQHYCCDLive: %f\n',toc);
    end
    
    QC.deallocate_image_buffer

end
