function loadQHYlibraryAndOpen(QC)
% Load the library if needed (this is global?)           
            if ~libisloaded('libqhyccd')
                classpath=fileparts(mfilename('fullpath'));
                classpath=fullfile(classpath,'..'); % now that this function is buried in /private
                % Quick and ugly patch to cope alternatively with:
                %  -- James Fidell packaging of the library, v6.0.x
                % or
                %  -- QHY original installer of LINUX_X64_qhyccd_V20200219_0
                % the two differ for location and content of the include files,
                %  and therefore I use temporarily two patched versions of
                %  the main include file qhyccd.h
                if exist('/usr/lib/x86_64-linux-gnu/libqhyccd.so.6','file')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_matlab.h'));
                elseif exist('/usr/local/lib/libqhyccd.so.20.2.19','file')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-2-19_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-2-19_matlab.h'));
                elseif exist('/usr/local/lib/libqhyccd.so.20.8.26.3','file')
                    % this one before 20-6-26, because 20-8 includes
                    % previous ones
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-8-26_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-8-26_matlab.h'));
                elseif exist('/usr/local/lib/libqhyccd.so.20.6.26','file')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-6-26_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-6-26_matlab.h'));
                elseif exist('/usr/local/lib/libqhyccd.so.21.2.1.10','file') ||...
                    exist('/usr/local/lib/libqhyccd.so.21.3.13.16','file')
                % sdk 21.03.13 fortunately has only a couple of additions
                %  in qhyccdcamdef.h with respect to its predecessor, and
                %  only changes in comments in qhyccd.h
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_21-2-1_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_21-2-1_matlab.h'));
                else
                    error('these QHY installations change all the time; what shall I do?')
                end
                % this could perhaps be called harmlessly multiple times,
                %  or does it interfere with previously constructed objects?
                InitQHYCCDResource;
                %[ret,version,major,minor,build]=GetQHYCCDSDKVersion()
                % ScanQHYCCD disconnects previously connected cameras, so we
                %  cannot make use of it for every new camera object created
                %  (probabily this is new of 2020 SDKs, what do I know)
                num=ScanQHYCCD;
                QC.report(sprintf('%d QHY cameras found\n',num));
            end
