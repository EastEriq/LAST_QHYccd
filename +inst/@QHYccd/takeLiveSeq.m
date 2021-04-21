function imgs=takeLiveSeq(QC,num,expTime)
% attempting once more to take live images, this time with the SDK
% 21-02-01 + 30-3-21
% Tested on QHY600 only, so far.
% TODO: instead of just storing the images in a big struct containing
%  only the image pixels, save also the retrieval times, and/or
%  allow the call of an external funtion which saves the images
%  with appropriate metadata

    if QC.verbose>1
        tic;
    end

    QC.initStreamMode(1);
    if QC.verbose>1
        fprintf('t after eventual reinitialization: %f\n',toc);
    end
    
    if exist('expTime','var')
        QC.ExpTime=expTime;
    else
        QC.ExpTime=QC.ExpTime;
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
        % we have no way at the moment of knowing the real start time
        %  of each usable exposure, this is essentially a placeholder
        QC.TimeStart=now;
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
    
    if QC.verbose
        fprintf('stopping live mode\n')
    end
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
