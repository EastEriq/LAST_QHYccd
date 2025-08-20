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
        [settable,minV,maxV,stepV]=GetQHYCCDParamMinMaxStep(QC.camhandle,control);
        fprintf('#%3d ',control);
        if available==0
            fprintf('AVAIL');
        else
            fprintf(' --- ');
        end
            value = GetQHYCCDParam(QC.camhandle,control);
            if value==2^32-1
                fprintf('   no value ');
            else
                fprintf(' %10g ',value);
            end
        if settable==0
            fprintf(' SET ')
        else
            fprintf(' --- ')
        end
        fprintf('[ %g : %g : %g]',minV,stepV,maxV)
        [ret,name]=GetQHYCCDControlName(QC.camhandle,i);
        if ret==0
            fprintf(' %s "%s"\n',s{i},name);
        else
            fprintf(' %s\n',s{i});
        end
    end
end
