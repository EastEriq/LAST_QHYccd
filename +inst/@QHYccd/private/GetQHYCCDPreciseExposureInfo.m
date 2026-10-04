function [ret,PixelPeriod,LinePeriod,FramePeriod,ClocksPerLine,...
              LinesPerFrame,ActualExposureTime,isLongExposureMode]=...
                                        GetQHYCCDPreciseExposureInfo(camhandle)
% from the .h file:
%   Get the sensor precise timing data from camera. These data can be used
%      for high precise GPS time calculation
%    camhandle camera control handle
%    PixelPeriod_ps return pixel period, unit is ps
%    LinePeriod_ns return row period, unit is ns
%    FramePeriod_us return frame period, unit is us
%    ClocksPerLine return how many clocks per line
%    LinesPerFrame return how many rows per frame. Please note this maybe not the picture y size.    
%    ActualExposureTime return actual exposure time. most cmos exposure is
%      row based. So the exposure time is n*row period. It maybe has a little
%      difference with the set value.
%    isLongExposureMode return if camera works in long exposure mode.
%      For cmos camera. When exposure time > frame period. It will add the
%      verical blanking rows. in this case it is long exposure mode
%     uint32_t *PixelPeriod_ps,
%     uint32_t *LinePeriod_ns,
%     uint32_t *FramePeriod_us,
%     uint32_t *ClocksPerLine,
%     uint32_t *LinesPerFrame,
%     uint32_t *ActualExposureTime,
%     uint8_t  *isLongExposureMode);

PPixelPeriod=libpointer('uint32Ptr',0);
PLinePeriod=libpointer('uint32Ptr',0);
PFramePeriod=libpointer('uint32Ptr',0);
PClocksPerLine=libpointer('uint32Ptr',0);
PLinesPerFrame=libpointer('uint32Ptr',0);
PActualExposureTime=libpointer('uint32Ptr',0);
PisLongExposureMode=libpointer('uint8Ptr',0);
[ret,~,PixelPeriod,LinePeriod,FramePeriod,ClocksPerLine,LinesPerFrame,...
    ActualExposureTime,isLongExposureMode]=...
    calllib('libqhyccd','GetQHYCCDPreciseExposureInfo',camhandle,...
             PPixelPeriod,PLinePeriod,PFramePeriod,PClocksPerLine,...
             PLinesPerFrame,PActualExposureTime,PisLongExposureMode);
