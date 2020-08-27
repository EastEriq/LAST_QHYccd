function releaseAndUnloadQHYlibrary()
% various actions "the last out turns off the light" in attempt
%  to exit cleanly from the SDK and avoid matlab crashes

    % this is undocumented BUT IT PREVENTS CRASHES!
    % is it right to do it when there are more than one QC
    %  objects?
    QHYCCDQuit

    % but:
    % don't release the SDK, other QC objects may be using it
    % Besides, releasing prevents reopening
    ReleaseQHYCCDResource;

    % unload the library,
    %  This, at least with libqhyccd 6.0.5 even crashes Matlab
    %  with multiple errors traced into libpthread.so (unless
    %  QHYCCDQuit is called before).
    % On the other side, unloadlibrary is the last resort for
    %  recovering usb communication or camera errors, and for
    %  allowing future reconnections to the cameras
    try
        % if another instantiation is still using the library, this
        % I hoped that it would fail. Instead, it seems to succeed,
        % so that the other instantiations cannot use library
        % functions anymore... Reason for commenting out
        pause(1)
        unloadlibrary('libqhyccd')
    catch
    end
