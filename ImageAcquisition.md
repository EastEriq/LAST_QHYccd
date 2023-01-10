# Different modes for taking images with LAST_QHYccd

Status of 28/4/2021. Things change, and SDK support is unstable.
Workings were checked with two QHY600 and one QHY367.

## Properties and methods discussed here:

### properties

+ `.StreamMode`: readonly state property, keeping track of the current acquisition mode,
   for calling expensive reinitialization code only when switching mode.
+ `.ImageHandler`: optional handle to a function for treating each acquired image
+ `.LastImage`, `.LastImageSaved`, `.TimeStart`, `.TimeEnd`, `.TimeStartLastImage`,
  `.TimeStartDelta`: last image acquired and information about its acquisition.
+ all other properties which should be preserved when changing acquisition mode:
  `ROI`, `Binning`, `BitDepth`, `Gain`, `Offset`, `Temperature`...

### methods

+ `.takeExposure(expTime)`:  **blocking**, take one image in Single Exposure mode.
+ `.startExposure(expTime)`: starts a single exposure, returns immediately.
+ `.collectExposure(varargin)`: **blocking**, waits for a single exposure to be available, and retrieves it
+ `.takeExposureSeq(num,expTime,varargin)`: **blocking**, take many images in Single Exposure mode.
+ `.takeLive(num,expTime,varargin)`: **non-blocking**, take many images in Live mode.
+ `.takeLiveSeq(num,expTime,varargin)`: **blocking**, take many images in Live mode.
+ `.startLive(expTime)`: **non-blocking**, starts continuous exposure in Live mode, returns immediately
+ `.collectLiveExposure(varargin)`: **blocking**, waits (with timeout) for the next live exposure
     to be available, and retrieves it.
+ `.abort`: stop any ongoing acquisition, stop and delete ImageCollector callbacks.

## Single Exposure vs. Live mode

QHY provides two working modes for their cameras. In **Single** mode the camera exposes only one frame, which can be retrieved after completion. In **Live** mode, the camera continuously exposes new frames without dead time (for exposures longer than a certain minimal time). The exposure time of all frames is set when starting the acquisition and cannot be changed along it.

There are two main issues with the operation:

1. Each of the modes involves a separate initialization, which takes several seconds to happen,
   and resets camera parameters formerly set;
2. Each mode has its own timing overheads before starting the process and for retrieving each image.
   These overheads are different and sometimes unjustified.

The matlab class code tries to mitigate the penalty of reinitialization, but it might be that some
quirks have escaped. For instance, as of now reinitialization forces the cameras to 16bit mode, 1x1
binning, full frame (including overscan area), without respecting the previous state.
Also, setting the QHY367 in Live mode causes Gain erroneously to be reset at 2000.

As of today, Live mode implies that the first image retrievable is only the _second_ one
after having started the process.
Since the exposure time canot be changed, this adds the duration of one exposure time to the initial overhead.

Currently, for the QHY600 the timings and overheads which I observed for retrieving 16bit, full frame images
are of the order of:

+ **Single Exposure**: 350ms pre-exposure, [_Texp_], 1600-1900ms image transfer time,
  50-100ms image unpacking time (CPU dependent)
+ **Live mode**: 450ms + _Texp_ pre-exposure, [_Texp_], 200-800ms image transfer time
 _(`USBTRAFFIC` dependent)_, 50-100ms image unpacking time (CPU dependent).
 Transfer rate is however limited at something like 1.2fps, even if Texp is
 shorter than 800msec (1.2fps for practical matlab programming reasons, the
 camera would be capable of ~2.2fps).

Thus acquring N exposures in Single Exposure mode will require about
 *N&times;(Texp+2.2*sec*)*, whereas in Live mode would require *~1*sec *+(N+1)&times;Texp*.

Switching among the two modes adds an overhead of ~4500ms the first time acquisition in a new mode is called.

With the QHY367 all overheads are not-really-proportionally smaller.

Theoretically there would be a third possible mode, **Burst**, likely designed to acquire a small number
of shortly exposed images at a high fps and to store them temporarily inside the camera DDR memory,
but we are given no information about its operation.

## Blocking vs. nonblocking (timed callbacks)

Blocking functions return command to the matlab prompt only when their operation is completed.
This may be a long time for long image sequences.

Non blocking functions arm a matlab timer for later collecting images, and return to the prompt as soon as
possible. Matlab is thus available for other operations while the acquisition is in progress.

The matlab timer created is always named `ImageCollector-N`, where N=`Q.CameraNum`. It
would not make sense to have more than one such object active at a time per camera. The timer function
is called back at interval of ExpTime when needed to get a new image.

Care has to be taken in that, while executing, the callback collector is itself busying matlab.
Moreover, other codes may make use of timers themselves, and matlab's event processor is single
threaded and cannot cope with concurrent events. Too fast
acquisition, or non-blocking simultaneous acquisition from multiple cameras can lead to delays and even
event thread lockup.

The command `.abort` stops any ongoing acquisition and deletes these timers.

## Retrieving images and acquisition of multiple frames

All methods store the last image acquired in `.LastImage`.

The methods `takeExposure`, `collectExposure`, `takeExposureSeq`  and `takeLiveSeq` can be can be called with
an output argument, e.g.
```
img=Q.takeExposure(2.5);
imgs=Q.takeExposureSeq(10,2.5);
imgs=Q.takeLiveSeq(10,2.5);
```
and return the image array(s) directly or in a struct (_Seq_ methods). The latter can be very memory
consuming for long sequences. (If called with no return assigment, they don't encumber memory).

Additionally and alternatively, _each_ newly acquired image can be treated (e.g. processed, displayed, saved)
by an user provided function, whose handle is assigned to `.ImageHandler`.

The methods `.takeLive` and `.collectLiveExposure` **only** support the latter way of retrieving images.

The function assigned to `.ImageHandler` must accept as first argument the camera object itself, but can take any number of further arguments. It is thus possible to pass to this function not only information about the camera
and `.LastImage` just acquired, but also for instance about the pier system.

Such additional arguments are passed transparently, as `varargin` arguments after the mandatory ones, to the
methods `.takeLive`, `.takeLiveSeq`, `.takeExposureSeq`, `.collectExposure` and `.collectLiveExposure`.

It is for example possible to call something like
```
Q.takeLive(10,2.5,mount_coordinates_whatever,focuser_something_else)
```
provided the handler knows what to do with them.

It is the entire responsibility of the user to supply the right additional arguments, if any, to the ImageHandler
function, and to write the function so that it treats them correctly.

## Examples of ImageHandler functions

Display the image in a figure, using `imagesc()`, using an example method provided along with the class:

```
Q.ImageHandler = @simpleshowimage
```

Simply output on screen the number of the camera and the timestamp when a new image arrives:

```
Q.ImageHandler = @(Q) fprintf([sprintf('%d--',Q.CameraNum),datestr(Q.TimeEnd,'HH:MM:SS.FFF\n')]);
```

## Example: simultaneous live acquisition from two cameras

```
% create camera objects
Q1=inst.QHYccd; Q1.connect(1);
Q2=inst.QHYccd; Q2.connect(2);

% pre-initialize the cameras in Live mode (not mandatory, only to get
%  a faster reply later) (trick - 0-lenght sequence)
Q1.takeLiveSeq(0);
Q2.takeLiveSeq(0);

% do whatever else

% take simultaneously 20 images and display them as they are taken
Q1.ImageHandler=@simpleshowimage;
Q2.ImageHandler=@simpleshowimage;
Q1.takeLive(20,2); Q2.takeLive(20,2)
```

## Instabilities and crashes

Segmentation faults and code freezes are the name of the game with QHY's SDK as we know. The Matlab code strives
to avoid situations leading to them, but can't everything.

Typical situations leading to problems:

+ clearing camera objects, without calling the `disconnect` method first
+ redefinition of camera objects, pointing to the same camera
  (which likely doesn't disconnect before reconnecting, the way the SDK can tolerate)
+ powering off cameras, even if all camera objects have been disconnected and properly cleared (!!!)
+ USB cabling issues: they cause low level communications errors which the SDK can't remediate. They
  can lead to failure to acquire, but also to freezes or crashes. Mostly they require power cycling
  the camera to restore (which, as said above, may crash Matlab as well).
  _Note -- there is an internal parameter `USBTRAFFIC` whose value could be tuned --
   the lower the value the faster the live transfer, but also less stable
   with multiple cameras/poor cables._

Simultaneous live acquisition from two cameras on the same computer can also lead to wondrous deadlocks
and matlab crashes, if the exposure time is shorter than maybe 0.6 sec. The crashes happen when sequence
acquisition is launched _for the second time_, unless a single frame acquisition or a live acquisition
with longer exposure times is called in between. I'd say that symptoms point to a thread-unsafety of
the SDK.

To reproduce, sequences have to be really almost simultaneous. A way is to call via `unitCS` code, like

```
P=obs.unitCS('02')
P.connect
P.takeExposure([],1e-4,2)
P.takeExposure([],1e-4,2)
```

Slaves fail to poll live images on the second call, and crash in various ways, sometimes reporting
failed assertions related to futex, pthreads and libusb.

See also the comments in `@QHYccd/private/initStreamMode.m`.
