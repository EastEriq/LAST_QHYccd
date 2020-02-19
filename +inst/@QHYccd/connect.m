        function connect(QC,cameranum)
            % Open the connection with a specific camera, and
            %  read from it some basic information like color capability,
            %  physical dimensions, etc.
            %  cameranum: int, number of the camera to open (as enumerated by the SDK)
            %     May be omitted. In that case the last camera is referred to
             
            num=ScanQHYCCD;
            if QC.verbose
                fprintf('%d QHY cameras found\n',num);
            end
            
            if ~exist('cameranum','var')
                cameranum=num; % and thus open the last camera
                                 % (TODO, if possible, the first not
                                 %  already open)
            end
            [ret,QC.CameraName]=GetQHYCCDId(max(min(cameranum,num)-1,0));
            
            if ret, return; end
            
            QC.camhandle=OpenQHYCCD(QC.CameraName);
            if QC.verbose
                fprintf('Opened camera "%s"\n',QC.CameraName);
            end
           
            InitQHYCCD(QC.camhandle);
            
            % query the camera and populate the QC structures with some
            %  characteristic values
            
            [ret1,QC.physical_size.chipw,QC.physical_size.chiph,...
                QC.physical_size.nx,QC.physical_size.ny,...
                QC.physical_size.pixelw,QC.physical_size.pixelh,...
                         bp_supported]=GetQHYCCDChipInfo(QC.camhandle);
            
            [ret2,QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                QC.effective_area.sxEff,QC.effective_area.syEff]=...
                         GetQHYCCDEffectiveArea(QC.camhandle);
            
            % warning: this returns strange numbers, which at some point
            %  I've also seen to change (maybe depending on other calls'
            %  order?)
            [ret3,QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
                QC.overscan_area.sxOver,QC.overscan_area.syOver]=...
                              GetQHYCCDOverScanArea(QC.camhandle);

            ret4=IsQHYCCDControlAvailable(QC.camhandle, qhyccdControl.CAM_COLOR);
            colorAvailable=(ret4>0 & ret4<5);

            if QC.verbose
                fprintf('%.3fx%.3fmm chip, %dx%d %.2fx%.2fµm pixels, %dbp\n',...
                    QC.physical_size.chipw,QC.physical_size.chiph,...
                    QC.physical_size.nx,QC.physical_size.ny,...
                    QC.physical_size.pixelw,QC.physical_size.pixelh,...
                     bp_supported)
                fprintf(' effective chip area: (%d,%d)+(%dx%d)\n',...
                    QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                    QC.effective_area.sxEff,QC.effective_area.syEff);
                fprintf(' overscan area: (%d,%d)+(%dx%d)\n',...
                    QC.overscan_area.x1Over,QC.overscan_area.y1Over,...
                    QC.overscan_area.sxOver,QC.overscan_area.syOver);
                if colorAvailable, fprintf(' Color camera\n'); end
            end
            
            [ret5,Nmodes]=GetQHYCCDNumberOfReadModes(QC.camhandle);
            if QC.verbose, fprintf('Read modes:\n'); end
            for mode=1:Nmodes
                [~,QC.readModesList(mode).name]=...
                    GetQHYCCDReadModeName(QC.camhandle,mode-1);
                [~,QC.readModesList(mode).resx,QC.readModesList(mode).resy]=...
                    GetQHYCCDReadModeResolution(QC.camhandle,mode-1);
                if QC.verbose
                    fprintf('(%d) %s: %dx%d\n',mode-1,QC.readModesList(mode).name,...
                        QC.readModesList(mode).resx,QC.readModesList(mode).resy);
                end
            end
            
            QC.success = (ret1==0 & ret2==0 & ret3==0);
                        
            % put here also some plausible parameter settings which are
            %  not likely to be changed
            
            QC.offset=0;
            colormode=false; % (local variable because no getter)
            QC.color=colormode;

            % USBtraffic value is said to affect glow. 30 is the value
            %   normally found in demos, it may need to be changed, also
            %   depending on USB2/3
            % The SDK manual says:
            %  Used to set camera traffic,the bandwidth setting is only valid
            %  for continuous mode, and the larger the bandwidth setting, the
            %  lower the frame rate, which can reduce the load of the
            %  computer.
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_USBTRAFFIC,3);

            % from https://www.qhyccd.com/bbs/index.php?topic=6861
            %  this is said to affect speed, annd accepting 0,1,2
            % The SDK manual says:
            %  USB transfer speed,but part of cameras not support
            %  this function.
            SetQHYCCDParam(QC.camhandle,qhyccdControl.CONTROL_SPEED,2);
            
            % set full area as ROI (?) -- wishful
            if colormode
                QC.ROI=[0,0,QC.physical_size.nx,QC.physical_size.ny];
            else
                % this is problematic in color mode
                SetQHYCCDParam(QC.camhandle,qhyccdControl.CAM_IGNOREOVERSCAN_INTERFACE,1);
                QC.ROI=[QC.effective_area.x1Eff,QC.effective_area.y1Eff,...
                        QC.effective_area.sxEff,QC.effective_area.syEff];
            end
            
        end
