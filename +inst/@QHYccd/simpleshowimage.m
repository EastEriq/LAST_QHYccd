function simpleshowimage(Q,varargin)
% sample handler function for displaying an acquired image, mainly for
%  testing
    figure(Q.CameraNum)
    set(gcf,'Name',Q.CameraName)
    imagesc(Q.LastImage)
    colorbar
    colormap gray
    if ~isempty(varargin) && isa(varargin{1},'char')
        title([varargin{1},datestr(Q.TimeEnd,'HH:MM:SS.FFF')])
    else
        title([datestr(Q.TimeEnd,'HH:MM:SS.FFF'),', ',...
              sprintf('t_{end}-t_{start}=%fs',(Q.TimeEnd-Q.TimeStart)*86400)])
    end
    drawnow