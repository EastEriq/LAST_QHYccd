## Working (as of now) with multiple cameras in the same matlab session, and handling potential disconnects

* the only way to understand if a camera is still reachable seems to be to try to take
 an exposure. If that fails after the exposure time, the camera has gone fishing.

* don't call `collectExposure()` twice, it hangs matlab (I seem to remember that, when using an SDK which blabbered on `stdout`, usb errors were reported)

* don't rely on reading or setting parameters. If the camera is gone, the SDK
 still behaves as if they are set. Probably the state is held in memory and not
 checked against the camera.

* don't disconnect and reconnect a camera. This crashes matlab on calling `InitQHYCCD()`.
The only way I have found to prevent that is to unload `liqqhyccd` completely.

* I've tried to handle initialization and closure in the following way: `liqqhyccd`
 is loaded and initialization functions are called only if `liqqhyccd` was not yet loaded;
 I close (`QHYCCDQuit; ReleaseQHYCCDResource; unloadlibrary('libqhyccd')`) only
 when the **base** matlab workspace contains no more objects of class `QHYccd`.
 This is so far ok if the objects are called interactively, may need to be revised if
 they are created by functions, and live in a child workspace.  
 Looking at the matlab objects is a workaround, as I don't know of an SDK function
 to count the opened cameras.

* if it is clear that a camera vanished, clear all QHYccd objects, and reconnect them.