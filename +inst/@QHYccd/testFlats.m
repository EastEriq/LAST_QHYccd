function Result = testFlats(Obj, Args)
    % Measure gain and non-linearity from flat images using different methods
    %   Measure the gain per pixel and take the average over all pixels,
    %   and measure gain from variance of multiple pixels in the same
    %   image.
    % Input  : - A inst.QHYccd object.
    %          * ...,key,val,...
    %            'Gain' - Vector of gain parameters to test.
    %            'Offset' - Vector of offsets, with the same length as the
    %                   gain parameter. The gain and offset are tested in
    %                   pairs.
    %            'Bias' - A dark image.
    %                   If this is a structure array, then each element
    %                   corresponds to one gain/offset, and the Coadd field
    %                   contains the dark image.
    %            -- see code for additional parameters
    % Output :
    % Author : Eran Ofek (Jun 2022)
    % Example: Rflat = P.Camera{2}.testFlats('Bias',D);
    
   
    arguments
        Obj
        Args.ReadMode     = 2;
        Args.Gain         = (0:10:80); % offset and gain must be of the same length
        Args.Offset       = [4     4     4     5     5     6     8    10    13];
        Args.Temperature  = -5;
        Args.FlatExpTime  = ones(1,30);
        Args.ExpTime      = [[0.1:0.1:1.2],[1.5:0.5:8]]; % [0.3 0.5 1 1.5 2 3 5 6 7 8];
        Args.NormExpTime  = 0.5;  % ExpTime by which to normalize
        Args.Bias         = [];  % or struct array with Coadd field
        %Args.CCDSEC       = [2700 3700 4300 5300];
        Args.CCDSEC       = [3100 3300 4700 4900];
    end
    
    if isempty(Args.Bias)
        error('Bias image must be provided');
    end
    
    Obj.ReadMode     = Args.ReadMode;
    
    Result.CameraName  = Obj.CameraName;
    
    Ngain   = numel(Args.Gain);
    Noffset = numel(Args.Offset);
    Ntemp   = numel(Args.Temperature);
    Nexp    = numel(Args.ExpTime);
    NexpF   = numel(Args.FlatExpTime);
    
    Result.Table = nan(Ntemp.*Ngain.*Noffset.*Nexp, 11);
    Fit   = nan(Ntemp.*Ngain.*Noffset, 8);
    Result.GainTable = nan(Ntemp.*Ngain,5);
    IndF = 0;                                                                                                                     
    Ind = 0;
    IndG = 0;
    for Itemp=1:1:Ntemp
        Temp = Args.Temperature(Itemp);
        Obj.Temperature = Temp;
        while abs(Obj.Temperature - Temp)>1
            fprintf('Waiting: Set temp: %f,   current temp: %f\n',Temp, Obj.Temperature);
            pause(30);
        end
        
        for Igain=1:1:Ngain
            if isstruct(Args.Bias)
                Bias = Args.Bias(Igain).Coadd;
            else
                Bias = Args.Bias;
            end
            
            
            Gain = Args.Gain(Igain);
            Obj.Gain = Gain;
            
            Ioffset = Igain;
            
            %for Ioffset=1:1:Noffset
                Offset = Args.Offset(Ioffset);
                Obj.Offset = Offset;
                
                % prep master flat
                for IexpF=1:1:NexpF
                    ExpTime    = Args.FlatExpTime(IexpF);
                    Obj.Object = sprintf('G%d.O%d',Gain,Offset);
                    Obj.SaveOnDisk = false;
                    Obj.takeExposure(ExpTime);
                    Obj.waitFinish;
                    Obj.SaveOnDisk = true;
                    if IexpF==1
                        SizeIm = size(Obj.LastImage);
                        Cube = zeros(SizeIm(1), SizeIm(2), NexpF);
                    end
                    Cube(:,:,IexpF) = single(Obj.LastImage) - single(Bias);
                end
                Flat = median(Cube,3, 'omitnan');
                Flat = Flat./median(Flat,'all');
                
                % gain per pixel
                StdPP  = std(Cube,[],3);
                MedPP  = median(Cube,3);
                GainPP = StdPP.^2./MedPP;
                IndG = IndG + 1;
                StdGain = tools.math.stat.rstd(GainPP(:));
                Result.GainTable(IndG,:) = [Temp, Gain, Offset, median(GainPP,'all','omitnan'), StdGain];
                
                
                % start measurments
                for Iexp=1:1:Nexp
                    Ind = Ind + 1;
                    ExpTime    = Args.ExpTime(Iexp);
                    Obj.Object = sprintf('G%d.O%d',Gain,Offset);
                    Obj.SaveOnDisk = false;
                    Obj.takeExposure(ExpTime);
                    Obj.waitFinish;
                    Obj.SaveOnDisk = true;
                    
                    Image = (single(Obj.LastImage) - single(Bias))./Flat;
                    Image = Image(Args.CCDSEC(3):Args.CCDSEC(4), Args.CCDSEC(1):Args.CCDSEC(2));
                    
                    Median = nanmedian(Image(:));
                    Mean   = nanmean(Image(:));
                    RStd   = tools.math.stat.rstd(Image(:));
                    Std    = nanstd(Image(:));
                    Max    = max(Image(:));
                    NpixMax= sum(Image(:)==Max);
                    MeasuredGain = (RStd.^2./Median);   % no sqrt!
                    Table(Ind,:) = [Temp, Gain, Offset, ExpTime, Median, RStd, Mean, Std, Max, NpixMax, MeasuredGain];
                    
                end
                
                % fit Gain and Bias
                
                % fit non-linearity
                IndF = IndF + 1;
                I = find(Table(:,1)==Temp & ...
                         Table(:,2)==Gain & ...
                         Table(:,3)==Offset & ...
                         Table(:,8)<5);
                      
                Iet1 = find(Table(I,4)==Args.NormExpTime);
                
                NI = numel(I);
                % fit Gain and Bias
                H = [ones(NI,1), Table(I,6).^2];
                [Par,ParErr] = lscov(H,Table(I,5));
                Par
                ParErr
                
                
                % design matrix for non-linearity fitting
                %H = [ones(NI,1), 
                
                Par1 = polyfit(Table(I,4)./Table(I(Iet1),4), Table(I,5)./Table(I(Iet1),5),1);
                Par2 = polyfit(Table(I,4)./Table(I(Iet1),4), Table(I,5)./Table(I(Iet1),5),2);
                Fit(IndF,:) = [Temp, Gain, Offset, Par1(1), Par1(2), Par2(1), Par2(2), Par2(3)];
            %end
        end
    end
    
    Result.Table = array2table(Table);
    Result.Table.Properties.VariableNames = {'Temp', 'Gain', 'Offset', 'ExpTime', 'Median', 'RStd', 'Mean','Std','Max', 'NpixMax', 'MeasuredGain'};
    
    Result.FitTable = array2table(Fit);
    Result.FitTable.Properties.VariableNames = {'Temp', 'Gain', 'Offset', 'Par1_1', 'Par1_2', 'Par2_1', 'Par2_2', 'Par2_3'};
    
    Result.GainTable = array2table(Result.GainTable);
    Result.GainTable.Properties.VariableNames = {'Temp', 'Gain', 'Offset', 'MedGainPP', 'StdGainPP'};
end