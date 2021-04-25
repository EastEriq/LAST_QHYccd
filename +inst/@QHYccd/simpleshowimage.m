function simpleshowimage(Q,varargin)
% sample handler function for displaying an acquired image, mainly for
%  testing
    imagesc(Q.LastImage)
    colorbar
    colormap gray
    if ~isempty(varargin) && isa(varargin{1},'char')
        title([varargin{1},datestr(Q.TimeEnd,'HH:MM:SS.FFF')])
    else
        title(datestr(Q.TimeEnd,'HH:MM:SS.FFF'))
    end
    drawnow