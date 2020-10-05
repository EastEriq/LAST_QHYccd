function default_values(QC)
% set some initial default values for properties, differentiating
%  between camera models when needed
    QC.ExpTime=10;
    QC.Gain=0;
    QC.Offset=1;
    QC.Binning=[1,1];
    
    switch QC.CameraName(1:6)
        case 'QHY600'
            QC.ReadMode=2;
            QC.Temperature=-20; % check if reachable...
        case 'QHY367'
            QC.Temperature=-20; % check if reachable...
        otherwise
    end
    
end
