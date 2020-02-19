# Modifications made to the original headers so that they work with Matlab: #

## In `qhyccd.h`:

Currently working with v6.0.5:

- excluded `SetQHYCCDLogFunction` if not C++; it is probably not usable by matlab becauses it uses function handles
- prototype `SetQHYCCDQuit` changed to `QHYCCDQuit`, since the latter is exported by `libqhyccd.so`.  
  What the function does is unknown, but calling when deleting the QHYccd object, **I got rid
  of matlab crashes** upon subsequent `unloadlibrary('libqhyccd')`
- commented prototype `SetQHYCCDCallBack`, which is probably not usable by matlab becauses it uses function handles

The set of alternate headers for working in conjunction of SDK v4.0.1 included more
modifications, see previous versions of this file.