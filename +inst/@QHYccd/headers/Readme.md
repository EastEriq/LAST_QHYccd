# Modifications made to the original headers so that they work with Matlab: #

Currently working with V20200219_0, QHY SDK, but leaving temporarily in support for v6.0.5 as installed from James Fidell's packages.

## Versions of 2020:

The stock headers of the SDK are installed in `/usr/local/include`.

### `qhyccd.h` --> `qhyccd2020_matlab.h`:

- defined `CONTROL_ID` as `uint16_t` (no idea why it wasn't necessary earlier)
- commented `SetQHYCCDLogFunction`; it is probably not usable by matlab becauses it uses function handles
- commented a probably redundant leftover `SetQHYCCDQuit` (`QHYCCDQuit` is defined below)
- commented `GetQHYCCDBeforeOpenReadMode`, avoids the problem of parsing in matlab a pointer to the
  structure `QHYCamReadModeInfo`
- commented prototype `SetQHYCCDCallBack`, which is probably not usable by matlab becauses it uses function handles

### `qhyccdstruct.h` --> `qhyccdstruct_matlab.h`:

- claused the nonempty #definitions of `EXPORTFUNC` and `EXPORTC` only for C++, like in James Fidell's version

## Up to version 6.0.5 (V20191016_0)

The stock headers of the SDK are installed in `/usr/include/qhyccd`.

### `qhyccd.h` --> `qhyccd_matlab.h`:

- excluded `SetQHYCCDLogFunction` if not C++; it is probably not usable by matlab becauses it uses function handles
- prototype `SetQHYCCDQuit` changed to `QHYCCDQuit`, since the latter is exported by `libqhyccd.so`.
  What the function does is unknown, but calling it when deleting the QHYccd object, **I got rid
  of matlab crashes** upon subsequent `unloadlibrary('libqhyccd')`
- commented prototype `SetQHYCCDCallBack`, which is probably not usable by matlab becauses it uses function handles

## Earlier versions:

The set of alternate headers for working in conjunction of SDK v4.0.1 included more
modifications, see previous versions of this file in [QHYccd-Matlab](https://github.com/EastEriq/QHYccd-matlab).
