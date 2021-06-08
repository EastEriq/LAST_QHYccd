function releaseAndUnloadQHYlibrary(QC)
% various actions "the last out turns off the light" in attempt
%  to exit cleanly from the SDK and avoid matlab crashes

    % this is undocumented BUT IT USED TO PREVENT CRASHES!
    % is it right to do it when there are more than one QC
    %  objects?
    QHYCCDQuit

    % but:
    % don't release the SDK, other QC objects may be using it
    % Besides, releasing prevents reopening
    ReleaseQHYCCDResource;
    
    QC.report('Released...\n')

    % unload the library. It is not that we are concerned with memory, it
    %  is that with some versions of the SDK it used to be the last resort
    %  for regaining connection with closed or disconnected or hung
    %  cameras. However the side effects are too unstable.
    % In older versions of the SDK like libqhyccd 6.0.5 unloading
    %  used to crash Matlab with multiple errors traced into libpthread.so
    %  (unless QHYCCDQuit is called before).
    % In some later versions the unloading may have been harmless, but
    %  in recent ones (2021) it causes a delayed segfault 
    %  in <unknown-module>+00000000, 30 sec after the unloading (which
    %  points to a timeout of a libusb watchdog or something the like,
    %  under the hood), or 2 seconds after camera poweroff
    %  (see LAST_QHYccd/Crashing/poweroff.m)
    % Hence, I think it is safer to comment it out and leave the library
    %  loaded.
    try
        % if another instantiation is still using the library, this
        % I hoped that it would fail. Instead, it seems to succeed,
        % so that the other instantiations cannot use library
        % functions anymore... Reason for commenting out
       % pause(1)
       % unloadlibrary('libqhyccd')
    catch
        QC.report('Error in unloading libqhyccd!!\n')
    end
