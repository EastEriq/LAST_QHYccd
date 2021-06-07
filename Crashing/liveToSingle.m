% Seemingly solved after careful reinitialization and
%  restoring of all mandatory parameters on mode change
% Possibly it was a segmentation fault simply due
%  to copying wrongly sized data in the correctly allocate image buffer,
%  wrongly sized because "incomplete" treatment of the above 

Q=inst.QHYccd;Q.connect;Q.Verbose=0; Q.DebugOutput=true;

imgs=Q.takeLiveSeq(3,1)
Q.takeExposure(1)

% I got a crash with:
% Stack Trace (from fault):
% [  0] 0x00007fdfa33e7869                    /lib/x86_64-linux-gnu/libc.so.6+01632361
% [  1] 0x00007fdd8a8c7fca                        /usr/local/lib/libqhyccd.so+01294282 _ZN11QHY5IIIBASE20ReadImageInDDR_TitanEPvjjjjiijjPhj+00002272
% [  2] 0x00007fdd8a922d39                        /usr/local/lib/libqhyccd.so+01666361 _ZN10QHY600BASE14GetSingleFrameEPvPjS1_S1_S1_Ph+00000911
% [  3] 0x00007fdd8a84bf2a                        /usr/local/lib/libqhyccd.so+00786218
% [  4] 0x00007fdd8a84c3d5                        /usr/local/lib/libqhyccd.so+00787413 GetQHYCCDSingleFrame+00000251
% [  5] 0x00007fde2c4e7616 /tmp/tpc6c39a8a_97df_4ccb_8900_f194342e3e63/libqhyccd_thunk_glnxa64.so+00009750 uint32voidPtrvoidPtrvoidPtrvoidPtrvoidPtrvoidPtrThunk+00000159

% but can't reproduce...

imagesc(Q.LastImage); colorbar  % but this reproducibly hangs! and needs
% powercycling?