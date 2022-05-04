% this has to be run in a spawned matlab session (with .Logging=true before
% .connect) so that stderr is saved

%name='QHY600M-9591234bb4884c26c'; %01_1_1
name='QHY600M-aa1c6f4fab9d48eab'; %01_1_2

% CONTROL_USBTRAFFIC is supported
expmode='single';
expmode='live';

for k=0:9
    diary(sprintf('%s_%s_Level_%d.log',name,expmode,k))
    fprintf('\n\n\n##### Loglevel %d #####\n\n',k);
    fprintf(2,'\n\n\n##### Loglevel %d #####\n\n',k);
    Q=inst.QHYccd;
    Q.Verbose=2;
    Q.connect(name);
    Q.DebugOutput=true;
    Q.DebugLogLevel=k;
    switch expmode
        case 'single'
            Q.takeExposure(1)
            pause(8)
        otherwise
            Q.takeLive(3,1)
            pause(12)
    end
    Q.disconnect;
    diary('off')
end