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
                if isfile('/usr/lib/x86_64-linux-gnu/libqhyccd.so.6')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_matlab.h'));
                elseif isfile('/usr/local/lib/libqhyccd.so.20.2.19')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-2-19_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-2-19_matlab.h'));
                elseif isfile('/usr/local/lib/libqhyccd.so.20.8.26.3')
                    % this one before 20-6-26, because 20-8 includes
                    % previous ones
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-8-26_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-8-26_matlab.h'));
                elseif isfile('/usr/local/lib/libqhyccd.so.20.6.26')
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_20-6-26_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_20-6-26_matlab.h'));
                elseif isfile('/usr/local/lib/libqhyccd.so.21.2.1.10') ||...
                    isfile('/usr/local/lib/libqhyccd.so.21.3.13.16') ||...
                    isfile('/usr/local/lib/libqhyccd.so.21.3.30.13') ||...
                    isfile('/usr/local/lib/libqhyccd.so.21.7.16.13') ||...
                    isfile('/usr/local/lib/libqhyccd.so.21.8.5.9') ||...
                    isfile('/usr/local/lib/libqhyccd.so.21.8.14.15')
                % sdk 21.03.13 fortunately has only a couple of additions
                %  in qhyccdcamdef.h with respect to its predecessor, and
                %  only changes in comments in qhyccd.h
                % 21.3.30.13 we got privately, only the .so.*, without *.h,
                %  we assume all prototypes are like the previous one
                % Later sdks, like 21.07.16, 21.08.05 are still fine with
                %  this...
                % For 21.8.5.9 and on it would be worth to make a new
                %  _matlab.h, there is at least one reset function which
                %  may be relevant for changing between still and live
                %  mode. TODO
                    loadlibrary('libqhyccd',...
                        fullfile(classpath,'headers/qhyccd_21-2-1_matlab.h'),...
                        'addheader',fullfile(classpath,'headers/qhyccdstruct_21-2-1_matlab.h'));
                else
                    error('these QHY installations change all the time; what shall I do?')
                end
                % try to enforce the debug logging status before init, maybe
                % it works
                QC.DebugOutput=QC.DebugOutput;
                % this could perhaps be called harmlessly multiple times,
                %  or does it interfere with previously constructed objects?
                InitQHYCCDResource;
                %[ret,version,major,minor,build]=GetQHYCCDSDKVersion()
                % ScanQHYCCD disconnects previously connected cameras, so we
                %  cannot make use of it for every new camera object created
                %  (probabily this is new of 2020 SDKs, what do I know)
                num=ScanQHYCCD;
                QC.report('%d QHY cameras found\n',num);
            end
