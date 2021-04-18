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

    ret=BeginQHYCCDLive(QC.camhandle);
    if QC.verbose>1
        fprintf('t after BeginQHYCCDLive: %f\n',toc);
    end
    if ret==0
        QC.CamStatus='exposing';
    else
        QC.CamStatus='unknown';
    end

    imgs=cell(1,num);
    for i=1:num
        if ~isempty(QC.LastError)
            break
        end 
        imgs{i}=collectLiveExposure(QC);
    end
    
    fprintf('stopping live mode\n')
    StopQHYCCDLive(QC.camhandle);
    if QC.verbose>1
        fprintf('t after StopQHYCCDLive: %f\n',toc);
    end
    QC.CamStatus='idle';
    
    QC.deallocate_image_buffer
    if QC.verbose>1
        fprintf('t after deallocating buffer: %f\n',toc);
    end

end
