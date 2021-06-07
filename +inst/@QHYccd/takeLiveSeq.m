function imgs=takeLiveSeq(QC,num,expTime,varargin)
% Take a series of num images with the same exposure time,
%  setting the camera in Live mode. This is a blocking function,
%  which returns only when the sequence is complete or if acquisition
%  times out.
% Transitioning from Single Frame to Live Mode takes some seconds
%  of initialization time, which are spent the first time this
%  method is called. To do it preemptively without really acquiring
%  images, call Q.takeLiveSeq(0).
% If the method is called with one return argument, all the images
%  are returned in a cell array. This can take up quite some space for
%  long sequences.
% Alternatively, to dispose of the images as soon as they are retrieved,
%  an user function can be used. The handle to that function is assigned
%  to the object property Q.ImageHandler. The function assigned there
%  receives the whole object Q as first argument, and transparently
%  any other further argument added to the call of
%
%    Q.takeLiveSeq(num,expTime,extra_args)
%
%  See the function simpleshowimage(Q,varargin) for an example:
%
%    Q.ImageHandler=@simpleshowimage
%    Q.takeLiveSeq(4,0.5,'retrieved at t=')
%
% another simple example
%
%    Q.ImageHandler=@(Q) fprintf([sprintf('%d--',Q.CameraNum),datestr(Q.TimeEnd,'HH:MM:SS.FFF\n')]);
    

    if QC.Verbose>1
        tic;
    end
    
    if exist('expTime','var')
        QC.ExpTime=expTime;
    end

    startLive(QC)
    if ~isempty(QC.LastError)
        return
    end

    if nargout>0
        imgs=cell(1,num);
    end
    for i=1:num
        if nargout>0
            imgs{i}=collectLiveExposure(QC,varargin{:});
        else
            collectLiveExposure(QC,varargin{:});
        end
        if ~isempty(QC.LastError)
            break
        else
            QC.report(sprintf('  got image %d/%d\n',i,num))
        end
    end
    
    QC.report('stopping live mode\n')
    StopQHYCCDLive(QC.camhandle);
    if QC.Verbose>1
        fprintf('t after StopQHYCCDLive: %f\n',toc);
    end
    QC.CamStatus='idle';
    
    QC.deallocate_image_buffer
    if QC.Verbose>1
        fprintf('t after deallocating buffer: %f\n',toc);
    end

end
