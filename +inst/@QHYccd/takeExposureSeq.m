function imgs=takeExposureSeq(QC,num,expTime)
% blocking function, take N images. This should be done in Live mode;
%  but since there are so many issues with it with the QHY, as a functional
%  placeholder we implement it as a repeated take of single exposures.
%  This implies a large overhead for reading and rearming the take each
%  time.
% The many issues of the QHY sdk for live mode include: cumbersome
% requirement for the order of calls for initializing the camera; different
% requirements for the QHY367 and the QHY600; inconsistent state reporting
% of the polling-for-image-ready function; overrun destroys sequence take;
% bad error recovery.

    
    if exist('expTime','var')
        QC.ExpTime=expTime;
    end

    % a slightly more efficient writeup would allocate only once the image
    %  buffer before the loop and deallocate it at the end, but here we go
    %  for economy of writing, since this is a placeholder

    if nargout>0
        imgs=cell(1,num);
    end
    for i=1:num
        startExposure(QC,expTime)
        
        if ~isempty(QC.LastError)
            return
        end

        if nargout>0
            imgs{i}=collectExposure(QC);
        else
            collectExposure(QC);
        end
        QC.report(sprintf('  got image %d/%d\n',i,num))
        
        if ~isempty(QC.LastError)
            return
        end
    end
    
end
