## Testing many cameras with libqhyccd.so.21.3.30.13

commit ab44d

Working hypoteses:

+ QHY367 no more supported
+ `GetQHYCCDLiveFrame(h2)` impossible if `BeginQHYCCDLive(h1)` is running
+ one frame not retrieved when changing from Live to Single if more cameras are connected

### single QHY600:

`Q=inst.QHYccd;Q.connect;Q.verbose=2; Q.DebugOutput=true;Q.ImageHandler=@simpleshowimage`

#### QHY600M-f66f2d469925fea7b, other USB cable disconnected from camera


#### QHY600M-9fc3db42b6306d371 (but other camera on and USB plugged in)

+ `Q.takeLive(3,0.5); Q.takeExposure(2)`: error retrieving frame from camera QHY600M-9fc3db42b6306d371
  for the first takeExposure; the second would be ok; subsequently, repeating
  `Q.takeLive(3,0.5);Q.takeExposureSeq(3,0.5)`:
  image timeout, ExpTime=5 (where from?), image timeout, hang.