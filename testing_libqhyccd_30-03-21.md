# Testing Live and Burst mode on latest QHY sdk

Testing on CFENRICO-PC01.

## cpp code

### Testing tasks:

1. created `LiveFrameSample3.cpp` merging the latest version of the demo code received with 30-03-21
  with previous versions of it, qxx corrections on the fly and my corrections to that
2. test repeated runs of the latest `LiveFrameSample.cpp` against sdk_linux64_21.03.13 currently installed
3. test repeated runs of `LiveFrameSample3.cpp` against sdk_linux64_21.03.13 currently installed
4. test repeated runs of `LiveFrameSample.cpp` replacing `/usr/local/lib/libqhyccd.so` with the
   latest received with 30-03-21
5. test repeated runs of `LiveFrameSample3.cpp` replacing `/usr/local/lib/libqhyccd.so` with the
   latest received with 30-03-21
6. check how fps is affected by exp time and bpp

### Comments and results:

+ compilation with:
`g++ LiveFrameSample3.cpp -o lfm -I /usr/local/include/ -L /usr/local/lib/ -lqhyccd`

1) `LiveFrameSample3.cpp` differs from the latest `LiveFrameSample.cpp` with respect of:

+ `SetQHYCCDBitsMode(camhandle,8)` vs `SetQHYCCDParam(camhandle, CONTROL_TRANSFERBIT, 8)`
+ correct computation of fps

The latest `LiveFrameSample.cpp` differs from earlier versions in that it allocates the image buffer
  _before_ `BeginQHYCCDLive()`

2) runs once successfully, hangs the second time, doesn’t find the camera the third, finds it again after a power cycle

3) ditto

+ replacement with:
`sudo cp libqhyccd.so.* /usr/local/lib/`

4) runs several times succesfully

5) ditto. Also aborting a run with Ctrl-C doesn't prevent the next run to acquire

6) fps is capped at 2.55fps for 8 bit, 1.6fps at 16 bit

### Current call order in the cpp

```
GetQHYCCDSDKVersion

InitQHYCCDResource();
ScanQHYCCD()
GetQHYCCDId

OpenQHYCCD
GetQHYCCDFWVersion
SetQHYCCDReadMode
IsQHYCCDControlAvailable(camhandle, CAM_LIVEVIDEOMODE);
SetQHYCCDStreamMode(camhandle,1);

InitQHYCCD
SetQHYCCDDebayerOnOff
GetQHYCCDChipInfo
SetQHYCCDBinMode
SetQHYCCDResolution
//SetQHYCCDBitsMode

SetQHYCCDParam(camhandle, CONTROL_TRANSFERBIT, 16)
SetQHYCCDParam(camhandle, CONTROL_GAIN, 10);
SetQHYCCDParam(camhandle, CONTROL_OFFSET, 10);
SetQHYCCDParam(camhandle, CONTROL_USBTRAFFIC, 30);
SetQHYCCDParam(camhandle, CONTROL_DDR, 1.0);
SetQHYCCDParam(camhandle, CONTROL_EXPOSURE, 20*1000);

GetQHYCCDMemLength

BeginQHYCCDLive
GetQHYCCDLiveFrame
StopQHYCCDLive

CloseQHYCCD
ReleaseQHYCCDResource
```

## Matlab

In principle we already know that the calling sequence in which first we set camera properties and then
repeatedly call LiveFrame is incompatible wit previous versions of the sdk, and there is no reason why
tht should have improved with 30-03-21. In fact the statement is:

>    "But if camera work on Live mode,you need call CloseQHYCCD and ReleaseQHYCCDResource,and
>     reconnect camera,call    StopQHYCCDLive and BeginQHYCCDLive is not available presently."

### Testing tasks:

1. I have already tested that attempts to reproduce (partially) the suggested call order cause
  `QHYGetLiveFrame` to return permanently -1, at the very least (if not harder crashes), with
  sdk_linux64_21.03.13
2. replace `/usr/local/lib/libqhyccd.so` with the latest received with 30-03-21, and update
  the loadlib script so that it builds the thunk file with it too
3. TODO check if the same attempts of LiveMode go any further with 30-03-21
4. check timings in SingleFrame mode with this newest .so
5. write wrappers for 6 Burst mode functions and experiment with them a little
6. write a set of sure-crash matlab scripts, for future reference and
   problem spotting

### Comments and results

3) Getting there with `Q.takeLiveSeq()`. Seems that the trick is to set again a number 
  of parameters after `InitQHYCCD()`, figuring out which.
  `GetQHYCCDLiveFrame()` now returns once a new value `0x7636800` before the first image, 
  besides -1 and 0. The value is not documented in `qhyccderr.h`.

  Investigating what are the timing implications, and if there are stability issues. E.g.,
  what happens if an image is not collected in time.

  Need to check and find solutions for
  interoperability with `Q.takeExposure()`, and whether acquiring a single frame in Live
  mode is competitive
  with SingleFrame mode.

4) execution of `GetQHYCCDSingleFrame()` reduces to 1900ms (for short exp) to 1650ms (long exp).
   It is already an achievement given the former 2400ms. I don't understand the inverse 
   dependence on texp.

5) written 7 wrappers, but I have no indication about their use besides the function and argument names.
   At best they only take integer input arguments besides the camera handle, I have no clue
   as for where the image data should be coming from. Full stop.

6) written a couple of them, which sometimes crash, sometimes not...