function listControlsSupported(QC)
    % list whether each possible qhyccdControl is supported or not
    %  by this camera (this is a debugging utility, not an API method)
    % I can't make really too much out of this report though. Some
    %  controls return unavailable, even though we are using them
    %  all the time, (notably CONTROL_EXPOSURE) and respond with a
    %  meaningful range; other return available,
    %  but reading their parameter range errors and returns zeros.
    % It might be that the report depends on the status of the camera
    %  at the moment of the query, or simply as usual, that everything is
    %  just fouled up
    [m,s]=enumeration('inst.qhyccdControl');
    fprintf('Controls supported:\n===================\n');
    for i=1:length(m)
        control=m(i);
        available=IsQHYCCDControlAvailable(QC.camhandle,m(i));
        [ret,minV,maxV,stepV]=GetQHYCCDParamMinMaxStep(QC.camhandle,control);
        if available
            fprintf('AVAIL ');
        else
            fprintf(' xxx  ');
        end
        if ret==0
            fprintf(' OK ')
        else
            fprintf('ERR ')
        end
        fprintf('[ %g : %g : %g]',minV,stepV,maxV)
        fprintf(' %s\n',s{i});
    end
end
