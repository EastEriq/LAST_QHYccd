classdef QHYccd < handle
 
    properties
        cameranum
    end
    
    properties(Dependent = true)
        % read/write properties, settings of the camera, for which
        %  hardware query is involved.
        %  We use getters/setters, even though instantiation
        %   order is not guaranteed. In particular, all parameters
        %   of the camera require that camhandle is obtained first.
        %  Values set here as default won't likely be passed to the camera
        %   when the object is created
        CamStatus
        CoolingStatus
        Temperature
        ExpTime
        Gain
        BinningX
        BinningY
        ROI % beware - SDK does not provide a getter for it, go figure
        ReadMode
    end
    
    properties(GetAccess = public, SetAccess = private)
        CameraName
    end
    
    % Enrico, discretional
    properties(GetAccess = public, SetAccess = private)
        physical_size=struct('chipw',[],'chiph',[],'pixelw',[],'pixelh',[],...
                             'nx',[],'ny',[]);
        effective_area=struct('x1Eff',[],'y1Eff',[],'sxEff',[],'syEff',[]);
        overscan_area=struct('x1Over',[],'y1Over',[],'sxOver',[],'syOver',[]);
        readModesList=struct('name',[],'resx',[],'resy',[]);
    end
    
    properties(GetAccess = public, SetAccess = private, Hidden)
        progressive_frame = 0; % image of a sequence already available
    end
    
    % settings which have not been prescribed by the API,
    % but for which I have already made the code
    properties(Hidden)
        offset
        color
        bitDepth
    end
    
    properties (Hidden,Transient)
        camhandle   % handle to the camera talked to - no need for the external
                    % consumer to know it
        lastError='';
        verbose=true;
        pImg  % pointer to the image buffer (can we gain anything in going
              %  to a double buffer model?)
              % Shall we allocate it only once on open(QC), or, like now,
              %  every time we start an acquisition?
    end

    methods
        % Constructor
        function QC=QHYccd(cameranum)
            %  cameranum: int, number of the camera to open (as enumerated by the SDK)
            %     May be omitted. In that case the last camera is referred to

            % Load the library if needed (this is global?)           
            if ~libisloaded('libqhyccd')
                classpath=fileparts(mfilename('fullpath'));
                loadlibrary('libqhyccd',...
                     fullfile(classpath,'headers/qhyccd_matlab.h'));
            end

            % this can be called harmlessly multiple times?
            InitQHYCCDResource;
            
            % the constructor tries also to open the camera
            if exist('cameranum','var')
                connect(QC,cameranum);
            else
                connect(QC);
            end
        end
        
        % Destructor
        function delete(QC)
            
            % it shouldn't harm to try to stop the acquisition for good,
            %  even if already stopped - and delete the image pointer QC.pImg
            abort(QC)
            
            % make sure we close the communication, if not done already
            success=disconnect(QC);
            QC.setLastError(success,'could not close camera')
            if success
                QC.report('Succesfully closed camera\n')
            else
                QC.report('Failed to close camera\n')
            end
            
            QHYCCDQuit % this is undocumented BUT IT PREVENTS CRASHES!
            
            % clear QC.pImg
            
            % but:
            % don't release the SDK, other QC objects may be using it
            % ReleaseQHYCCDResource
            
            % nor unload the library,
            %  which at least with libqhyccd 6.0.5 even crashes Matlab
            %  with multiple errors traced into libpthread.so
            % unloadlibrary('libqhyccd')
        end
        
    end
    
    methods %getters and setters
        
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

        
        function set.offset(QC,offset)
            success=(SetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_OFFSET,offset)==0);
            QC.setLastError(success,'could not set offset')
        end
        
        function offset=get.offset(QC)
            % Offset seems to be a sort of bias, black level
            offset=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_OFFSET);
            % check whether err=double(FFFFFFFF)...
            success=(offset>0 & offset<2e6);
            QC.setLastError(success,'could not get offset')
        end
        
        function set.color(QC,ColorMode)
            % default has to be bw
             success=(SetQHYCCDDebayerOnOff(QC.camhandle,ColorMode)==0);
             QC.setLastError(success,'could not set color mode')
             if ColorMode
                 QC.bitDepth=8; % segfault in buffer -> image otherwise
             end
        end

        function set.bitDepth(QC,BitDepth)
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
            if BitDepth==16; QC.color=false; end
        end

        function bitDepth=get.bitDepth(QC)
            bitDepth=GetQHYCCDParam(QC.camhandle,inst.qhyccdControl.CONTROL_TRANSFERBIT);
            % check whether err=double(FFFFFFFF)...
            success=(bitDepth==8 | bitDepth==16);
            QC.setLastError(success,'could not get bit depth')
        end

    end
    
end