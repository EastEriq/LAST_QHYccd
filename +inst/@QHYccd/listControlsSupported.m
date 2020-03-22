function listControlsSupported(QC)
    % list whether each possible qhyccdControl is supported or not
    %  by this camera (this is a debugging utility, not an API method)
    [m,s]=enumeration('inst.qhyccdControl');
    fprintf('Controls supported:\n===================\n');
    for i=1:length(m)
        if IsQHYCCDControlAvailable(QC.camhandle,m(i))
            fprintf('XX');
        else
            fprintf('++');
        end
        fprintf(' %s\n',s{i});
    end
end
