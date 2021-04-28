function [ret,PixelPeriod,LinePeriod,FramePeriod,ClocksPerLine,...
              LinesPerFrame,ActualExposureTime,isLongExposureMode]=...
                                        GetQHYCCDPreciseExposureInfo(camhandle)
                                    
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
