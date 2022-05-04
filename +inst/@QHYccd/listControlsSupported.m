function listControlsSupported(QC)
    % list whether each possible qhyccdControl is supported or not
    %  by this camera (this is a debugging utility, not an API method)
    [m,s]=enumeration('inst.qhyccdControl');
    fprintf('Controls supported:\n===================\n');
    for i=1:length(m)
        control=m(i);
        available=IsQHYCCDControlAvailable(QC.camhandle,m(i));
        [ret,minV,maxV,stepV]=GetQHYCCDParamMinMaxStep(QC.camhandle,control);
        if available
            fprintf('AVAIL ');
        else
            fprintf('UNAVA ');
        end
        if ret==0
            fprintf('OK ')
        else
            fprintf('ERR ')
        end
        fprintf('[%05d:%05d:%05d]',minV,stepV,maxV)
        fprintf(' %s\n',s{i});
    end
end
