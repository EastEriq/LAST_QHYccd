function simpleshowimage(Q)
% sample handler function for displaying an acquired image, mainly for
%  testing
    imagesc(Q.LastImage)
    colorbar
    colormap gray
    title(datestr(Q.TimeEnd,'HH:MM:SS.FFF'))
    drawnow