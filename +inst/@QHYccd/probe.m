function probed=probe(QC)
% probing function for LIPP
    texp=QC.ExpTime;
    probed = texp>0 && texp<4294;
end