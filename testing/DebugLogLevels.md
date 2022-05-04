## observations on debug LogLevels of the QHY SDK


It seems that the minimal LogLevel to get lots of output on `Q.connect` is 4. For single frame, Level 5 adds some information, higher numbers up to 9 nothing more. For a simple session connecting to the camera, setting the modes, taking a single frame and disconnecting, already at level 4 the debug log makes up 23119 lines!! In contrast, at level 4 in triplet live mode, the log has only ~3500 lines.

For smaller numbers, either

- `|QHYCCD|/var/lib/jenkins/workspace/SDK_SVN_1_13/QHYCCD_SDK_CrossPlatform/src/qhyccd.cpp|SetQHYCCDLogLevel start`

or

- `QHYCCD||EnableQHYCCDMessage| set gl_msgEnable from:  1  to: 1`

are printed (on `Q.DebugOutput=true;`), but seemingly not always/consistently

## 4

## 5

adds output, ~250 lines, notably of:

- `QHYCCD|QHYCCD.CPP|ScanQHYCCD|START`
- `QHYCCD.CPP -> getCameraList()` *[only up to 9 possible?]*
- `QHYCCD|QHY600M.CPP|IsChipHasFunction|controlID`
- more on chip resolution, camera capabilities


## occasional differences:

```
QHYCCD|QHYCCD.CPP|OpenQHYCCD|22222222222 wrong ID, Skip
QHYCCD|QHYCCD.CPP|OpenQHYCCD| paramID=QHY600M-aa1c6f4fab9d48eab     index=1  indexCamId=QHY600M-aa1c6f4fab9d48eab
```

occasional number variations in:

- `QHYCCD|QHYCCD.CPP|OpenQHYCCD|===========>`
- `QHYCCD|QHY600BASE.CPP|ThreadCountExposureTime|Time after execution of the first command`
- `QHYCCD|QHY5IIIBASE.CPP|readDDRNumEris| ddrnumber` and `QHYCCD|QHY5IIIBASE.CPP|ReadImageInDDR_Titan| Data In DDR`
- `QHYCCD|QHY600BASE.CPP|QHY600BasePixelReAlignment|GPS|`
- `==========================>  totalRead:`
   and
  `QHYCCD|QHY5IIIBASE.CPP|ReadImageInDDR_Titan|           + Head +     start_position`

## notable messages in live mode

```
QHYCCD|QHY600BASE.CPP|ERROR:SetChipResolution|roixstart 24 + roixsize 9600 > chipoutputsizex 9600
QHYCCD|QHY600BASE.CPP|SetChipResolution|Correct the above issue by reduce the roixstart to 0 and roixsize is 9600
```

multiple times despite successful image take:

```
QHYCCDRD|CMOSDLL.CPP|IoThread|frame data error
```
(this can be a dozen of times); and, tens of times at StopQHYCCDLive

```
QHYCCD|LIBUSBIO.CPP|asyImageDataCallBack|LIBUSB_TRANSFER_CANCELLED
```
