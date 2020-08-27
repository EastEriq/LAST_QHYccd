function num=howManyQHYCCDobjects()
% Check the base workspace, and return the number of objects of class QHYCCD.
% Why, because. To work with the QHY SDK, we load the library and
%  call some initializers when the first object is created. We assume
%  that the exit functions must be called only when the last one is
%  destroyed, and the library can be unloaded. Any other way may crash
%  matlab.
% In other words, fuck you, retarded bitches.
    S=evalin('base','whos()');
    num=sum(contains(string({S.class}),'QHYccd'));