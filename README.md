# LAST_QHYccd

LAST hardware driver for QHY cameras.

One needs to install the QHY SDK first. See the ramblings in [the dedicated file](InstallingQHYsdk.md).

See the project where all this started from: [QHYccd-Matlab](https://github.com/EastEriq/QHYccd-matlab).


## Useful links about camera functioning, from QHY:

- [Setting GAIN and OFFSET on cold CMOS camera for deep sky astrophotography](https://www.qhyccd.com/file/repository/PDF/Setting%20GAIN%20and%20OFFSET%20on%20cold%20CMOS%20camera%20for%20deep%20sky%20astrophotography.pdf) (pdf)

- [How to set gain and offset for cooled cmos camera](https://www.qhyccd.com/bbs/index.php?topic=6281.msg32546#msg32546) forum thread starting from the previous document

- [QHY16200A Gain and Offset](https://www.qhyccd.com/bbs/index.php?topic=6309.msg32704#msg32704) forum thread

- [Specs of the QHY600](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=94&id=55&cut=1)
 Scroll down for graphs of: **System gain**, **Readout noise**, **Full well capacity**,
  **Dynamic range**  for the three read modes, and **Linearity test**
   ([see also](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=23&id=273)),
   **Relative spectral sensitivity** (see also
    [measurement of the absolute QE](https://www.qhyccd.com/index.php?m=content&c=index&a=show&catid=23&id=261))