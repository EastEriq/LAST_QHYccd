function [Result, Dark, DC] = testOffset(Obj, Args)
    % A script to estimate the required Offset parameter
    %   The function takes images at a grid of Gain and Offset parameters
    %   and counts the number of pixels with 0,1,2 counts and some image
    %   statistics - a report is generated for the user.
    % Input : - An inst.QHYccd object
    %         * ...,key,val,...
    %           'Gain' - A vector of Gain parameters to test
    %               Default is [0 20 40 60 80]
    %           'Offset' - A vector of Offset parameters to test.
    %               Default is [2:18].
    %           See code for additional arguments
    % Output : - A structure array with a summary of measurments as a
    %            function of Gain and Offset.
    %          - Return a master dark for each gain at its recomended
    %            offset.
    %          - Return the result of testDarkCurrent for each gain and its
    %            recomended offset.
    % Author : Eran Ofek (jun 2022)
    % Example: [R,D,DC]=P.Camera{1}.testOffset
   
    arguments
        Obj
        Args.Temperature = -5;
        Args.ExpTime     = 1;
        
        Args.ReadMode    = [2];
        Args.Gain        = (0:10:80); %[0 20 40 60 80];
        
        Args.Offset      = [2:18]; %(1:1:10);
        Args.KeepImage   = false;
        
        Args.DarkNim     = 10;
    end
    
    Obj.Temperature = Args.Temperature;
    
    ReadMode     = Args.ReadMode;
    Obj.ReadMode = ReadMode;
    
    Result.CameraName  = Obj.CameraName;
    Result.Temperature = Args.Temperature;
    Result.Mode        = ReadMode;
    
    Noffset = numel(Args.Offset);
    Ngain   = numel(Args.Gain);
    for Igain=1:1:Ngain
        Gain = Args.Gain(Igain);
        
        % search offset
        for Ioffset=1:1:Noffset
            Offset = Args.Offset(Ioffset);
            
            Obj.Gain   = Gain;
            Obj.Offset = Offset;
            
            Obj.Object = sprintf('G%d.O%d',Gain,Offset);
            Obj.SaveOnDisk = false;
            Obj.takeExposure(Args.ExpTime);
            Obj.waitFinish;
            Obj.SaveOnDisk = true;
            
            Result.Gain(Igain).Offset.Offset(Ioffset) = Offset;
            Result.Gain(Igain).Offset.N0(Ioffset) = sum(Obj.LastImage(:)==0);
            Result.Gain(Igain).Offset.N1(Ioffset) = sum(Obj.LastImage(:)==1);
            Result.Gain(Igain).Offset.N2(Ioffset) = sum(Obj.LastImage(:)==2);
            Result.Gain(Igain).Offset.Median(Ioffset) = nanmedian(single(Obj.LastImage(:)));
            Result.Gain(Igain).Offset.Std(Ioffset)    = nanstd(single(Obj.LastImage(:)));
            Result.Gain(Igain).Offset.RStd(Ioffset)   = tools.math.stat.rstd(single(Obj.LastImage(:)));
            
            if Args.KeepImage
                Result.Gain(Igain).Offset.Image = single(Obj.LastImage);
            end
        end
        
        Igood = find(Result.Gain(Igain).Offset.N0<50 & ...
                     Result.Gain(Igain).Offset.N0>=0 & ...
                     Result.Gain(Igain).Offset.N1<50 & ...
                     Result.Gain(Igain).Offset.N2<100, 1, 'first');
        if numel(Igood)==0
            % no recomendation
            Result.Gain(Igain).RecomendedOffset          = NaN;
            Result.Gain(Igain).RecomendedOffsetMedian    = NaN;
            Result.Gain(Igain).RecomendedOffsetStd       = NaN;
            Result.Gain(Igain).RecomendedOffsetMediaRStd = NaN;
        else
            Result.Gain(Igain).RecomendedOffset = Result.Gain(Igain).Offset.Offset(Igood);
            Result.Gain(Igain).RecomendedOffsetMedian    = Result.Gain(Igain).Offset.Median(Igood);
            Result.Gain(Igain).RecomendedOffsetStd       = Result.Gain(Igain).Offset.Std(Igood);
            Result.Gain(Igain).RecomendedOffsetRStd      = Result.Gain(Igain).Offset.RStd(Igood);
        end
    end
    
    % for each gain get dark image at each best offset 
    if nargout>1
        for Igain=1:1:Ngain
            Gain = Args.Gain(Igain);
            
            Offset = Result.Gain(Igain).RecomendedOffset;
            
            Obj.Gain   = Gain;
            Obj.Offset = Offset;
            
            
            for Iim=1:1:Args.DarkNim
            
                Obj.Object = sprintf('G%d.O%d',Gain,Offset);
                Obj.SaveOnDisk = false;
                Obj.takeExposure(Args.ExpTime);
                Obj.waitFinish;
                Obj.SaveOnDisk = true;

                if Iim==1
                    Size = size(Obj.LastImage);
                    Cube = zeros(Size(1), Size(2), Args.DarkNim, 'single');
                end
                Cube(:,:,Iim) = single(Obj.LastImage);
            end
            Dark(Igain).Gain   = Gain;
            Dark(Igain).Offset = Offset;
            Dark(Igain).Coadd  = imUtil.image.stackCube(Cube,'StackMethod','sigmaclip','IndexDim',3);
            Dark(Igain).CoaddRVar = imUtil.image.stackCube(Cube,'StackMethod','rvar','IndexDim',3);
        end
        
        if nargout>2
            % dark current
            for Igain=1:1:Ngain
                Gain = Args.Gain(Igain);
            
                Offset = Result.Gain(Igain).RecomendedOffset;
                DC(Igain) = Obj.testDarkCurrent('Temperature',Args.Temperature, 'Gain',Gain, 'Offset',Offset);
            end
            
            
        end
    end
            
        
end
