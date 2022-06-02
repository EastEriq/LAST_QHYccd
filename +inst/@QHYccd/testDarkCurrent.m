function Result = testDarkCurrent(Obj, Args)
    % Measure dark current of detector as a function of parameters
    %   (for each Temp, Gain, Offset)
    % Input  : - An inst.QHYccd object.
    %          * ...,key,val,...
    %            See code
    % Output : - A structure with:
    %            .Table - A table of all measurments (median, rstd, vs par)
    %            .FitTable - Table of fitted dark current + bias slopes.
    % Author : Eran Ofek (Jun 2022)
    % Example: Rdc=P.Camera{1}.testDarkCurrent
   
    arguments
        Obj
        Args.ReadMode     = 2;
        Args.Gain         = 0;
        Args.Offset       = [3 10];
        Args.ExpTime      = [1 3 10 30 100];
        Args.Temperature  = [-5];
    end
    
    Obj.ReadMode     = Args.ReadMode;
    
    Ngain   = numel(Args.Gain);
    Noffset = numel(Args.Offset);
    Ntemp   = numel(Args.Temperature);
    Nexp    = numel(Args.ExpTime);
    
    Table = nan(Ntemp.*Ngain.*Noffset.*Nexp, 6);
    Fit   = nan(Ntemp.*Ngain.*Noffset, 5);
    Ind = 0;
    IndF = 0;
    for Itemp=1:1:Ntemp
        Temp = Args.Temperature(Itemp);
        Obj.Temperature = Temp;
        while abs(Obj.Temperature - Temp)>1
            fprintf('Waiting: Set temp: %f,   current temp: %f\n',Temp, Obj.Temperature);
            pause(30);
        end
        
        for Igain=1:1:Ngain
            Gain = Args.Gain(Igain);
            Obj.Gain = Gain;
            for Ioffset=1:1:Noffset
                Offset = Args.Offset(Ioffset);
                Obj.Offset = Offset;
                
                % start measurments
                for Iexp=1:1:Nexp
                    Ind = Ind + 1;
                    ExpTime    = Args.ExpTime(Iexp);
                    Obj.Object = sprintf('G%d.O%d',Gain,Offset);
                    Obj.SaveOnDisk = false;
                    Obj.takeExposure(ExpTime);
                    Obj.waitFinish;
                    Obj.SaveOnDisk = true;
                    
                    Median = nanmedian(single(Obj.LastImage(:)));
                    RStd   = tools.math.stat.rstd(single(Obj.LastImage(:)));
                    Table(Ind,:) = [Temp, Gain, Offset, ExpTime, Median, RStd];
                end
                IndF = IndF + 1;
                I = find(Table(:,1)==Temp & ...
                         Table(:,2)==Gain & ...
                         Table(:,3)==Offset);
                Par = polyfit(Table(I,4),Table(I,5),1);
                Fit(IndF,:) = [Temp, Gain, Offset, Par(1), Par(2)];
                         
            end
        end
    end    
    
    Result.Table = array2table(Table);
    Result.Table.Properties.VariableNames = {'Temp', 'Gain','Offset', 'ExpTime', 'Median', 'RStd'};
    
    Result.FitTable = array2table(Fit);
    Result.FitTable.Properties.VariableNames = {'Temp', 'Gain','Offset', 'Par1', 'Par2'};
    
end