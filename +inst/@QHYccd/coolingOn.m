function coolingOn(QC,temp)
% Turn cooling on and set target temperature, if given
% the default target temperature, if not given, is -20°C (arbitrarily)
    if ~exist('temp','var')
        temp=-20;
    end
    QC.Temperature=temp;
end