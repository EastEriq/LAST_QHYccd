function imgs=takeExposureSeq(QC,num,expTime,varargin)
% Take a series of num images with the same exposure time,
%  setting the camera in Single Frame mode, and iterating
%  exposure and retrieval of single frames. This is a blocking function,
%  which returns only when the sequence is complete or if acquisition
%  times out.
% This mode of operation implies larger dead time than Live mode
%  acquisition, but has been seen as much less problematic
%  with earlier versions of the SQK, and more consistent in operation
%  with either the QHY367 and the QHY600.
% Transitioning from Live to Single Frame Mode takes some seconds
%  of initialization time, which are spent the first time this
%  method is called.
% If the method is called with one return argument, all the images
%  are returned in a cell array. This can take up quite some space for
%  long sequences.
% Alternatively, to dispose of the images as soon as they are retrieved,
%  an user function can be used. The handle to that function is assigned
%  to the object property Q.ImageHandler. The function assigned there
%  receives the whole object Q as first argument, and transparently
%  any other further argument added to the call of 
%    Q.takeExposureSeq(num,expTime,extra_args)
%
%  See the function simpleshowimage(Q,varargin) for an example:
%
%    Q.ImageHandler=@simpleshowimage
%    Q.takeExposureSeq(4,0.5,'retrieved at t=')

    
    if exist('expTime','var')
        QC.ExpTime=expTime;
    end

    % a slightly more efficient writeup would allocate only once the image
    %  buffer before the loop and deallocate it at the end, but here we go
    %  for economy of writing, since this is a placeholder

    if nargout>0
        imgs=cell(1,num);
    end
    
    QC.SequenceLength=num;
    for i=1:num
        startExposure(QC,QC.ExpTime)
        
        if ~isempty(QC.LastError)
            return
        end

        if nargout>0
            imgs{i}=collectExposure(QC,varargin{:});
        else
            collectExposure(QC,varargin{:});
        end
        QC.report(sprintf('  got image %d/%d\n',i,num))
        
        if ~isempty(QC.LastError)
            return
        end
    end
    
end
