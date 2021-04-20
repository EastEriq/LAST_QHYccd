classdef QHYccd < obs.LAST_Handle
 
    properties
        CameraNum
        % read/write properties, settings of the camera, for which
        %  hardware query is involved.
        %  We use getters/setters, even though instantiation
        %   order is not guaranteed. In particular, all parameters
        %   of the camera require that camhandle is obtained first.
        %  Values set here as default won't likely be passed to the camera
        %   when the object is created
        Binning=[1,1]; % beware - SDK does not provide a getter for it, go figure
        ExpTime=10;
        Gain=0;
    end
    
    properties(Transient)
        LastImage % the last image acquired is copied here
        ImageHandler=struct('function',[],'keyvalues',{}); % what to do of every acquired image
    end

    properties(Dependent = true)
        Temperature
        ROI % beware - SDK does not provide a getter for it, go figure
        ReadMode
        Offset
    end
    
    properties(GetAccess = public, SetAccess = private)
        CameraName
        CamStatus='unknown';
        CoolingStatus
        CoolingPower
        % Humidity  % probably not always supported, and units unknown
        % Pressure  % Ditto
        TimeStart; % timestamp immediately after ExpQHYCCDSingleFrame() is called
        TimeEnd; % timestamp after GetQHYCCDSingleFrame() is called
        TimeStartLastImage % copy of TimeStart when LastImage is filled, valid until LastImage is not overwritten
   end
    
    % Enrico, discretional
    properties(GetAccess = public, SetAccess = private, Hidden)
        physical_size=struct('chipw',[],'chiph',[],'pixelw',[],'pixelh',[],...
                             'nx',[],'ny',[]);
        effective_area=struct('x1Eff',[],'y1Eff',[],'sxEff',[],'syEff',[]);
        overscan_area=struct('x1Over',[],'y1Over',[],'sxOver',[],'syOver',[]);
        readModesList=struct('name',[],'resx',[],'resy',[]);
        lastExpTime=NaN;
        progressive_frame = 0; % image of a sequence already available
        TimeStartDelta % uncertainty, after-before calling exposure start
        StreamMode % 0=single frame, 1=Live. Keep track as property because sdk doesn't retrieve it
    end
    
    % settings which have not been prescribed by the API,
    % but for which I have already made the code
    properties(Hidden)
        Color
        BitDepth
        DebugOutput % if set true, library blabber is printed on stderr
    end
    
    properties (Hidden,Transient)
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
        LastError='';
        verbose=true;
        pImg  % pointer to the image buffer (can we gain anything in going
              %  to a double buffer model?)
              % Shall we allocate it only once on open(QC), or, like now,
              %  every time we start an acquisition?
        LastImageSaved=false; % set true by the abstractor when saving the image, reset to false at new exposure
    end

    methods
        % Constructor
        function QC=QHYccd(CameraNum)
            %  CameraNum: int, number of the camera to open (as enumerated by the SDK)
            %     May be omitted. If so, that connection is deferred to when
            %     connect() is separatly called.

            % this is done only if libqhyccd is not already loaded  
            loadQHYlibraryAndOpen(QC);   

            % Don't open the camera when constructed. Some details are
            % inserted at the connect phase of the wrapper method
            % (obs.camera.connect), so connect only seperately.
            % DP - 2020 Sep 1
            
%             % open the camera when the object is constructed, if CameraNum is
%             %  given
%             % David commented out on 15/7/2020 because
%             % "not connecting in the constructor phase. MIGHT help solving 
%             %  retriving data problem."
%             % If that is it, just instantiate without a CameraNum
%             if exist('CameraNum','var')
%                 connect(QC,CameraNum);
%             else
% %                connect(QC);
%             end

        end 
        
        % Destructor
        function delete(QC)
            
            % do all this only if the QC object has been effectively
            % connected to a camera
            if ~isempty(QC.camhandle)
                % it shouldn't harm to try to stop the acquisition for good,
                %  even if already stopped - and delete the image pointer QC.pImg
                abort(QC)
                
                % make sure we close the communication, if not done already
                success=disconnect(QC);
                QC.setLastError(success,'could not close camera')
                if success
                    QC.report(['Succesfully closed "' QC.CameraName '"\n'])
                else
                    QC.report('Failed to close camera\n')
                end
                
                if howManyQHYCCDobjects()==0
                    QC.report('last QHY object destroyed, releasing library\n')
                    releaseAndUnloadQHYlibrary()
                end
            end
        end
        
    end
    
    methods %getters and setters
        
        function status=get.CamStatus(QC)
            % forget about getting any info about what the camera is doing
            %  directly fom it. At best we could try to implement some
            %  bookkeeping via class internal state variables. 
            switch QC.CamStatus
                case 'exposing'
                    if (now-QC.TimeStart)*24*3600 > QC.lastExpTime
                       QC.CamStatus='reading'; % means, ready to read
                    end
            end
            status=QC.CamStatus;
        end
        
        function set.Temperature(QC,Temp)
            % set the target sensor temperature in Celsius
            % We assume that we are working with newer cameras
            %  which can be controlled directly in temperature. Older
            %  cameras are said to have to be controlled in PWM. Support for
            %  both would imply IsQHYCCDControlAvaliable() for
            %  CONTROL_MANULPWM rather than CONTROL_COOLER,
            %  then setting them. Moreover, it seems that for older
            %  cameras PWM had to be set again and again to keep cooling...
            % Alternatively, this:
            % success=ControlQHYCCDTemp(QC.camhandle,Temp);
            success=SetQHYCCDParam(QC.camhandle,...
                inst.qhyccdControl.CONTROL_COOLER,Temp)==0;
            QC.setLastError(success,'could not set temperature')
        end
        
        function Temp=get.Temperature(QC)
            Temp=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CAM_CHIPTEMPERATURESENSOR_INTERFACE);
            % I guess that error is Temp=FFFFFFFF, check
            success = (Temp>-100 & Temp<100);
            QC.setLastError(success,'could not get temperature')
        end
        
%         function humidity=get.Humidity(QC)
%             humidity=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CAM_HUMIDITY);
%             % units and behavior in case of error or nonexistent control unknown
%         end
%         
%         function pressure=get.Pressure(QC)
%             pressure=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CAM_PRESSURE);
%             % units and behavior in case of error or nonexistent control unknown
%         end
        
        function status=get.CoolingStatus(QC)
            % get the current cooling status, by checking the current PWM
            % applied to the cooler.
            pwm=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_CURPWM);
%            QC.report(sprintf('current cooler PWM %.1f%%%%\n',pwm/2.55))
%            temp=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_COOLER);
%            QC.report(sprintf('current target T %.1f°C\n',temp))
            if pwm==0
                status='off';
            elseif pwm<=255
                status='on';
            else
                status='unknown';
            end
        end
        
        function CoolingPower=get.CoolingPower(QC)
            % Get the current cooling percentage
            CoolingPower=round(GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_CURPWM)./255.*1000)./10;
        end
        
        function set.ExpTime(QC,ExpTime)
            % ExpTime in seconds
            %QC.report(sprintf('setting exposure time to %f sec.\n',ExpTime))
            success=...
                (SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6)==0);
            QC.setLastError(success,'could not set exposure time')
        end
        
        function ExpTime=get.ExpTime(QC)
            % ExpTime in seconds
            ExpTime=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_EXPOSURE)/1e6;
            % if QC.verbose, fprintf('Exposure time is %f sec.\n',ExpTime); end
            success=(ExpTime~=1e6*hex2dec('FFFFFFFF'));            
            QC.setLastError(success,'could not get exposure time')
        end

        function set.Gain(QC,Gain)
            % for an explanation of gain & offset vs. dynamics, see
            %  https://www.qhyccd.com/bbs/index.php?topic=6281.msg32546#msg32546
            %  https://www.qhyccd.com/bbs/index.php?topic=6309.msg32704#msg32704
            success=(SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_GAIN,Gain)==0);          
            QC.setLastError(success,'could not set gain')
        end
        
        function Gain=get.Gain(QC)
            Gain=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_GAIN);
            % check whether err=double(FFFFFFFF)...
            success=(Gain>=0 & Gain<2e6);
            QC.setLastError(success,'could not get gain')
        end
        
        % ROI - assuming that this is what the SDK calls "Resolution"
        function set.ROI(QC,roi)
            % resolution is [x1,y1,sizex,sizey]
            %  I highly suspect that this setting is very problematic
            %   especially in color mode.
            %  Safe values should be [0,0,physical_size.nx,physical_size.ny]
            x1=roi(1);
            y1=roi(2);
            sx=roi(3)-roi(1)+1;
            sy=roi(4)-roi(2)+1;
            
            % try to clip unreasonable values
            x1=max(min(x1,QC.physical_size.nx-1),0);
            y1=max(min(y1,QC.physical_size.ny-1),0);
            sx=max(min(sx,QC.physical_size.nx-x1),1);
            sy=max(min(sy,QC.physical_size.ny-y1),1);
            
            success=(SetQHYCCDResolution(QC.camhandle,x1,y1,sx,sy)==0);
            QC.setLastError(success,'could not set ROI')
            if success
                QC.report(sprintf('ROI successfully set to (%d,%d)+(%dx%d)\n',...
                          x1,y1,sx,sy));
            else
                QC.report(sprintf('set ROI to (%d,%d)+(%dx%d) FAILED\n',x1,y1,sx,sy));
            end
        end

        
        function set.Offset(QC,Offset)
            success=(SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_OFFSET,Offset)==0);
            QC.setLastError(success,'could not set offset')
        end
        
        function Offset=get.Offset(QC)
            % Offset seems to be a sort of bias, black level
            Offset=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_OFFSET);
            % check whether err=double(FFFFFFFF)...
            success=(Offset>=0 & Offset<2e6);
            QC.setLastError(success,'could not get offset')
        end
        
        function set.ReadMode(QC,readMode)
            success=(SetQHYCCDReadMode(QC.camhandle,readMode)==0);
            if ~success
                QC.report(sprintf('Invalid read mode! Legal is %d:%d\n',0,...
                    numel(QC.readModesList)-1));
            end
            QC.setLastError(success,'could not set the read mode')
        end
        
        function currentReadMode=get.ReadMode(QC)
            [ret,currentReadMode]=GetQHYCCDReadMode(QC.camhandle);
            success= ret==0 & (currentReadMode>0 & currentReadMode<2e6);
            QC.setLastError(success,'could not get the read mode')
        end
        
        function set.Binning(QC,Binning)
            % default is 1x1
            % for the QHY367, 1x1 and 2x2 seem to work; NxN with N>2 gives error,
            %  NxM gives no error, but all are uneffective and fall back to 1x1
            success= (SetQHYCCDBinMode(QC.camhandle,Binning(1),Binning(2))==0);
            QC.setLastError(success,'could not set the read mode')
        end
        
        % The SDK doesn't provide a function for getting the current
        %  binning, go figure

        function set.Color(QC,ColorMode)
            % default has to be bw
             success=(SetQHYCCDDebayerOnOff(QC.camhandle,ColorMode)==0);
             QC.setLastError(success,'could not set color mode')
             if ColorMode
                 QC.BitDepth=8; % segfault in buffer -> image otherwise
             end
        end

        function set.BitDepth(QC,BitDepth)
            % BitDepth: 8 or 16 (bit). My understanding is that this is in
            %  first place a communication setting, which however implies
            %  the scaling of the raw ADC readout. IIUC, e.g. a 14bit ADC
            %  readout is upshifted to full 16 bit range in 16bit mode.
            % Constrain BitDepth to 8|16, the functions wouldn't give any
            %  error anyway for different values.
            BitDepth=max(min(round(BitDepth/8)*8,16),8);
            QC.report(sprintf('Setting depth to %dbit\n',BitDepth))
            SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_TRANSFERBIT,BitDepth);
            % There is also a second SDK function for setting this. I don't
            %  know if they are *really* equivalent. In doubt call both.
            success=(SetQHYCCDBitsMode(QC.camhandle,BitDepth)==0);
            QC.setLastError(success,'could not set bit depth')

            % ensure that color is set off if 16 bit (otherwise segfault!)
            if BitDepth==16; QC.Color=false; end
        end

        function BitDepth=get.BitDepth(QC)
            BitDepth=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_TRANSFERBIT);
            % check whether err=double(FFFFFFFF)...
            success=(BitDepth==8 | BitDepth==16);
            QC.setLastError(success,'could not get bit depth')
        end

        function set.DebugOutput(QC,flag)
            % undocumented functions, suppress or enable stderr trace of
            %  calls
            EnableQHYCCDMessage(flag) % this was probably for the log file,
            % in later SDKs it turns on the stderr trace
            SetQHYCCDLogLevel(10) % this one affects the verbosity of the blabber
        end
    end
    
end
