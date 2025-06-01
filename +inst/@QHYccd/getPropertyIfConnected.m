function value=getPropertyIfConnected(QC,property)
% wrapper, which attempts to read a property value only if the serial
% resource is defined and open, so to avoid unnecessary "cannot read"
% error messages, e.g. when polling continuously
if ~isNull(QC.camhandle)
    value=QC.(property);
else
    value=[];
end