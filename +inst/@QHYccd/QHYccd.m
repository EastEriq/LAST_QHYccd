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
        ReadMode
    end
    
    properties(GetAccess = public, SetAccess = private)
        CameraName
    end
    
    
    % Enrico, discretional
    properties(GetAccess = public, SetAccess = private)
        progressive_frame = 0; % image of a sequence already available
        physical_size=struct('chipw',[],'chiph',[],'pixelw',[],'pixelh',[],...
                             'nx',[],'ny',[]);
        effective_area=struct('x1Eff',[],'y1Eff',[],'sxEff',[],'syEff',[]);
        overscan_area=struct('x1Over',[],'y1Over',[],'sxOver',[],'syOver',[]);
        readModesList=struct('name',[],'resx',[],'resy',[]);
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
            if (close_camera(QC)==0)
                QC.report('Succesfully closed camera\n')
                QC.lastError='';
            else
                QC.report('Failed to close camera\n')
                QC.lastError='Failed to close camera';
            end
            
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
    
end