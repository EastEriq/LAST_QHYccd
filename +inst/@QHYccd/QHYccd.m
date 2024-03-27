classdef QHYccd < obs.camera

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
        ROI % beware - SDK does not provide a getter for it, go figure
    end
    
    properties (Description='api,type_Connected=logical')
        Connected; % untyped, because the setter may receive a logical or a string
    end
    
    properties (Description='api,must-be-connected, type_ExpTime=double, type_Gain=double')
        ExpTime double =10; % must leave them untyped so API passes a string?
        Gain double =0;
    end

    properties(Transient, SetObservable)
        LastImage % the last image acquired is copied here
    end

    properties(Dependent = true, Description='api,must-be-connected, type=double')
        Temperature double
        ReadMode double
        Offset double
    end
    
    properties(GetAccess = public, SetAccess = private, Description='api,must-be-connected,type_CamStatus=string')
        CamStatus char = 'unknown';
    end

    properties(GetAccess = public, SetAccess = private)
        CameraName char = '';
        CameraModel char = ''
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
        ProgressiveFrame double % progressive frame number when a sequence of exposures is requested
        SequenceLength double % total number of frames requested for the sequence
        TimeStartDelta % uncertainty, after-before calling exposure start
        StreamMode % 0=single frame, 1=Live. Keep track as property because sdk doesn't retrieve it
    end
    
    % settings which have not been prescribed by the API,
    % but for which I have already made the code
    properties(Hidden)
        Color
        BitDepth
        DebugOutput=false; % if set true, library blabber is printed on stderr
        DebugLogLevel=10; % the higher, the more verbose; no idea what each number does
    end
    
    properties (Hidden,Transient)
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
        pImg  % pointer to the image buffer (can we gain anything in going
              %  to a double buffer model?)
              % Shall we allocate it only once on open(QC), or, like now,
              %  every time we start an acquisition?
        LastImageSaved=false; % set true by the abstractor when saving the image, reset to false at new exposure
        ImageHandler function_handle % function to treat every acquired image, e.g. @simpleshowimage
    end

    
    methods
        % Constructor
        function QC=QHYccd(Locator)
            %  id: the logical Id label of the camera (see parent
            %      constructor)
            % Now REQUIRES locator. Think at implications
            if exist('Locator','var')
                if isa(Locator,'obs.api.Locator')
                    id = Locator.Canonical;
                elseif isa(Locator,'char') || isa(Locator,'string')
                    L=obs.api.Locator('Location',Locator);
                    id=L.Canonical;
                else
                    id='';
                end
            else
                id='';
            end
            % call the parent constructor
            QC=QC@obs.camera(id);
            % load libqhyccd on first time  
            loadQHYlibraryAndOpen(QC);
            QC.Connected=false;
        end 
        
        % Destructor
        function delete(QC)
            %fprintf('deleting camera object...\n')
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
                
                % if I put this out of the if, i.e. if I try even for an
                % object never connected to a camera, QC.report doesn't exist
                % anymore. why?
                if howManyQHYCCDobjects()==0
                    % maybe I could consider also
                    %  [~,~,c]=inmem;
                    %  if any(contains(c,'inst.QHYccd'))
                    % but at this point 'inst.QHYccd' is not anymore in
                    % memory. There is something I don't grasp about
                    %  scoping and destructor/nodestructor, maybe
                    QC.report('last QHY object destroyed, releasing library\n')
                    QC.releaseAndUnloadQHYlibrary()
                end
            end
        end
        
    end
    
    methods %getters and setters
        
        function set.Connected(QC,tf)
            % when called via the API, the argument is received as a string
            if isa(tf,'string')
                tf=eval(tf);
            end
            if isempty(QC.Connected)
                QC.Connected=false;
            end
            % don't try to connect if already connected, as per API wiki
            if ~QC.Connected && tf
                QC.Connected=QC.connect;
            elseif QC.Connected && ~tf
                QC.Connected=~QC.disconnect;
            end
        end

        function model=get.CameraModel(QC)
            [ret,model]=GetQHYCCDModel(QC.CameraName);
            if ret
                QC.reportError('could not read QHY camera model - maybe camera not yet connected?')
            end
        end
        
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
%            QC.report('current cooler PWM %.1f%%%%\n',pwm/2.55)
%            temp=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_COOLER);
%            QC.report('current target T %.1f°C\n',temp)
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
            %QC.report('setting exposure time to %f sec.\n',ExpTime)
            success=...
                (SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_EXPOSURE,ExpTime*1e6)==0);
            QC.setLastError(success,'could not set exposure time')
        end
        
        function ExpTime=get.ExpTime(QC)
            % ExpTime in seconds
            ExpTime=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_EXPOSURE)/1e6;
            % if QC.Verbose, fprintf('Exposure time is %f sec.\n',ExpTime); end
            success=(ExpTime~=1e6*hex2dec('FFFFFFFF'));            
            QC.setLastError(success,'could not get exposure time')
            if QC.Verbose>2
                [~,PixelPeriod,LinePeriod,FramePeriod,ClocksPerLine,...
              LinesPerFrame,ActualExposureTime,isLongExposureMode]=...
                                        GetQHYCCDPreciseExposureInfo(QC.camhandle);
                QC.report(['Periods: pixel %dps, line %dns, frame %dus;\n',...
                    '%d clocks/line, %d lines/frame; actual Texp=%d (long=%d)\n'],...
                    PixelPeriod,LinePeriod,FramePeriod,ClocksPerLine,...
                    LinesPerFrame,ActualExposureTime,isLongExposureMode)
            end
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
            if ~success
                QC.reportError('set ROI to (%d,%d)+(%dx%d) FAILED\n',x1,y1,sx,sy);
            end
        end

        % TODO, perhaps, only for recent (>8.2021 versions of the SDK)
%         function roi=get.ROI(QC)
%             % perhaps with GetQHYCCDCurrentROI, if that is real
%         end
        
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
            % read current Gain, because it has to be reset
            gain=QC.Gain;
            success=(SetQHYCCDReadMode(QC.camhandle,readMode)==0);
            if ~success
                [~,Nmodes]=GetQHYCCDNumberOfReadModes(QC.camhandle);
                QC.report('Invalid read mode! Legal is %d:%d\n',0,...
                    Nmodes-1);
            end
            QC.setLastError(success,'could not set the read mode')
            QC.Gain=gain;
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
            if numel(Binning)==1
                Binning=[Binning,Binning];
            end
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
            QC.reportDebug('Setting depth to %dbit\n',BitDepth)
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
            %  inner library calls
            % EnableQHYCCDLogFile(flag) % tries to open .qhyccd/qhyccd.log,
                                        % but segfaults matlab as soon as it tries
                                        % to write there (see comments in
                                        % the function file)
            EnableQHYCCDMessage(flag) % this was probably for the log file,
            % in later SDKs it turns on the stderr trace
        end
        
        function set.DebugLogLevel(QC,level)
            % This one affects the verbosity of the blabber. Possibly, 0 means off.
            %  Since it does not depend on a specific camera, probaby when there
            %  are many QC objects and the property is set for one, it affects the
            %  behavior of all. There is no getter function.
            SetQHYCCDLogLevel(level)
        end
    end
    
        % prototpes of exported methods, which are defined in separate files

    methods(Description='api,must-be-connected')
        abort(QC)
        takeExposure(QC) % exp time set from property
        takeLive(QC,num) % ditto
        out = probe(QC)
    end


end
