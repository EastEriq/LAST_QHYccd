function imgs=takeLiveSeq(QC,num,expTime)
% attempting once more to take live images, this time with the SDK 21-02-01

    imgs={};
    
    if exist('expTime','var')
        QC.ExpTime=expTime;
    end

    if contains(QC.CameraName,'QHY600')
        SetQHYCCDStreamMode(QC.camhandle,1);
        InitQHYCCD(QC.camhandle);
    else
        InitQHYCCD(QC.camhandle);
        SetQHYCCDStreamMode(QC.camhandle,1);
    end
    
    BeginQHYCCDLive(QC.camhandle);

    QC.allocate_image_buffer

    for i=1:num

        if ~isempty(QC.LastError)
            return
        end
        
        ret=-1;
        while ret~=0
            [ret,w,h,bp,channels]=GetQHYCCDLiveFrame(QC.camhandle,QC.pImg);
            pause(0.5)
            fprintf('%s\n',dec2hex(ret))
        end
        fprintf('got image %d\n',i)
        
        imgs{i}=unpackImgBuffer(QC.pImg,w,h,channels,bp);
        
        if ~isempty(QC.LastError)
            return
        end
    end
    
    fprintf('stopping live mode')
    StopQHYCCDLive(QC.camhandle);
    fprintf('live mode stopped')
    
    QC.deallocate_image_buffer

end
