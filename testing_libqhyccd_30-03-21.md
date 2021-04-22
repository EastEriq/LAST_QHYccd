# Testing Live and Burst mode on QHY sdk_linux64_21.03.13 + libqhyccd.so.21.3.30.13

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

1) My `LiveFrameSample3.cpp` differs from the latest `LiveFrameSample.cpp` received, with respect of:

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
that should have improved with 30-03-21. In fact the statement is:

>    "But if camera work on Live mode,you need call CloseQHYCCD and ReleaseQHYCCDResource,and
>     reconnect camera,call    StopQHYCCDLive and BeginQHYCCDLive is not available presently."

### Testing tasks:

1. I have already tested that attempts to reproduce (partially) the suggested call order cause
  `QHYGetLiveFrame` to return permanently -1, at the very least (if not harder crashes), with
  sdk_linux64_21.03.13
2. replace `/usr/local/lib/libqhyccd.so` with the latest received with 30-03-21, and update
  the loadlib script so that it builds the thunk file with it too
3. check if the same attempts of LiveMode go any further with 30-03-21
4. check timings in SingleFrame mode with this newest .so
5. write wrappers for 7 Burst mode functions and experiment with them a little
6. write a set of sure-crash matlab scripts, for future reference and
   problem spotting

### Comments and results

3) Getting there with `Q.takeLiveSeq()`. Seems that the trick is to set again a number
  of parameters after `InitQHYCCD()`, figuring out which.

  `GetQHYCCDLiveFrame()` now returns once a new value `0x7636800` before the first image,
  besides -1 and 0. The value is not documented in `qhyccderr.h`. _Maybe that flags
  something like "initialization done, ready to retrieve last image now"?_. Yes!
  and that is about 2*texp after beginning, for long exposures. From there, another texp
  is required before the first image can be retrieved.

  Investigating what are the timing implications, and if there are stability issues.

  It seems that nothing bad happens if an image is not collected in time, and `GetQHYCCDLiveFrame()`
  is called late (I don't know which image is actually read, though, the latest or the first unread).

  Need to check and find solutions for
  interoperability with `Q.takeExposure()`, and whether acquiring a single frame in Live
  mode is competitive with SingleFrame mode, in terms of calling overheads and of course
  stability.

  Short answers: 1) probably one needs a disconnect/connect cycle to change mode (not
  doing so, I have gotten corrupted single frame images after a live sequence; but live
  after single frame seems ok). 2) Live mode has clearly an overhead of 3 exposure
  times + calling overheads before the first image can be retrieved, Single frame
  only involves a fixed initial overhead of ~200ms and a post exposure transfer overhead of 1600ms
  (see next point).

  Checked if a trick can be played out, like setting initially a short texp to get a fast
  initialization, to change it to longer exposure afterwards - apparently not, it produces
  a) return values `0x7636800` at random calls also for frames after the first, b) corrupted images
  (vertical full height blocks with different exposure times).

  Checked if by chance the controls `CAM_SINGLEFRAMEMODE` and `CAM_LIVEVIDEOMODE` can be
  read or set, and if setting them is an alternative to `SetQHYCCDStreamMode()`. **They are
  reported as supported by `IsQHYCCDControlAvailable()`, but any attempt of accessing
  them or checking their ranges reports -1**.

4) execution of `GetQHYCCDSingleFrame()` reduces to 1900ms (for short exp) to 1650ms (long exp).
   It is already an achievement given the former 2400ms. I don't understand the inverse
   dependence on texp.

  Checked the effect of control parameters like CONTROL_USBTRAFFIC. On fora it is said that
  the lower the value the higher the fps. Its range is {0:60}.

  As for Live mode, indeed a value of 0 produces a frame transfer time of ~450ms (full frame, 16bit),
  30 of ~600ms, and 60 of ~850ms.

  For single frame mode, I already noted a comment in some file about it being non relevant,
  AND last year
  [I wrote](https://www.qhyccd.com/bbs/index.php?topic=7525.0) that I observed no timing
  difference. This remains valid also with the present combination.

5) written 7 wrappers, but I have no indication about their use besides the function and argument names.
   At best they only take integer input arguments besides the camera handle, I have no clue
   as for where the image data should be coming from. Maybe through callbacks (which would a bit
   of pain to implement from matlab). In absence of further info, full stop.

  On the QHY site, two cameras are mentioned using the Burst mode:
  [QHY42PRO](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=30&id=236) and
  [QHY4040](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=138&id=50&cut=3).
  _"If you need this mode please contact QHYCCD for details"_.

  As a further guess, there are some control names possibly connected to the DDR memory:
  `CONTROL_DDR`, `DDR_BUFFER_CAPACITY`, `DDR_BUFFER_READ_THRESHOLD`. Another hint,
  we received a contraption called "Guider", and the preceding control name is
   `CAM_QHY5II_GUIDE_MODE`. **Checked**: Neither is supported.

6) written a couple of them, which sometimes crash, sometimes not...

Since we are at it, I thought of checking support, min/max values and effect of `CONTROL_ROWNOISERE`,
which may turn on/off the row noise reduction: **Not Supported for QHY600**.

## Mandatory parameters which have to be reset after `InitQHYCCD()`

The demo cpp sets 8 parameters, let's see which are essential and the effect of not resetting them.

+ `Q.Color=false` not setting it causes a segfault at the second sequence
+ `QC.Binning=[1,1]` not setting it causes
  `__pthread_mutex_lock: Assertion 'mutex->__data.__owner == 0' failed`. and camera lockup,
  demanding power cycle, sometimes not at the first sequence
+ `SetQHYCCDResolution()` not setting it causes timeout at the first frame
+ `QC.BitDepth=16` Not setting it causes the appearance of the new return code `3B1B400` at the first
 frame, for a change, a few calls after the 0, dark images on first sequence,
 and crash at the second sequence;
+ `Q.Gain` and `Q.Offset` maybe they are persistent and don't need to be reset,
  at least Gain seems to persist (but recheck)
+ `Q.ExpTime` needs to be reset, otherwise it is apparently set to 0 or something the like.
+ `CONTROL_USBTRAFFIC` probably doesn't have to be reset, the former value is kept.
+ `CONTROL_DDR` not setting has caused me once an
  `Assertion 'new_prio == -1 || (new_prio >= fifo_min_prio && new_prio <= fifo_max_prio)' failed`
  crash, other times worked...

## Application notes

+ Repeated and alternated calling of SingleFrame and LiveFrame without disconnection is now possible, but
 needed a lot of care in resetting calling `SetQHYCCDStreamMode()` _before_ `InitQHYCCD()` in each case,
 **and** resetting the said parameters.

+ Skip only one (instead of two) initial frames in Live mode is achieved by calling
     ```
     SetQHYCCDBurstModePatchNumber(QC.camhandle,32001)
     ```
  after `InitQHYCCD()` (private communication by Qiu Hongyun).