% this has to be run in a spawned matlab session (with .Logging=true before
% .connect) so that stderr is saved

%name='QHY600M-9591234bb4884c26c'; %01_1_1
%name='QHY600M-aa1c6f4fab9d48eab'; %01_1_2
name='QHY600M-e69896449e35647d5'; %Ron's camera
% CONTROL_USBTRAFFIC is supported
%expmode='single';
expmode='live';

%R=Redis('localhost', 6379, 'password', 'foobared'); % Open Redis 
%!ssh ron@10.23.3.12 "/home/ron/miniforge3/bin/python /home/ron/Documents/python/test_input3_udp.py"

formatSpec='%d %3.3f ';
for k=0:308
    diary(sprintf('%s_%s_Level_%d.log',name,expmode,k))
    fprintf('\n\n\n##### Loglevel %d #####\n\n',k);
    fprintf(2,'\n\n\n##### Loglevel %d #####\n\n',k);
    Q=inst.QHYccd;
    Q.Verbose=2;
    Q.connect(name);
    Q.DebugOutput=true;
    Q.DebugLogLevel=0;
    
    switch expmode
        case 'single'
            Q.takeExposure(1)
            pause(8)
        otherwise
            t2 = sleep_until_next_minute();
            t3 = datetime('now','Format','dd-MMM-yyyy HH:mm:ss.SSS');
            fprintf('finished: %.0f\n',1000*second(t3));
            
    %==============================================================
            Q.takeLive(3,1.)  % n, t_exposure[s]
    %==============================================================            
            pause(12)
    end
    Q.disconnect;
    diary('off')
    %Q.saveCurImage('/last06e/data/Ron/ron_fits/')
    
    ms = str2double(Q.PVstore.get('last_time_ms'))
    sec = str2num(Q.PVstore.get('last_time_sec'))
    
    %fid =fopen('~/Documents/results.txt', 'a+' );
    %fprintf(fid, formatSpec, sec, ms);
    %fclose(fid);
    
    %%%%%%%%%%%%%%%%%!python3 /home/ocs/Documents/python/open__last_fits_file.py
    
end
%Q.saveCurImage('~/ron_fits')