function offset = RollingShutterEndOffset(QC,row)
% reported row time offset, apparently in us. For the QHY600, it appears to
% be 1974.286 for the first two rows, and to increase of 86.388 every second row
    [ret,offset] = GetQHYCCDRollingShutterEndOffset(QC.camhandle,row);
    if ret~=0
        QC.reportError('cannot get row offset time')
    end
end
