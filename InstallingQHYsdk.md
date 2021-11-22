# Installation of QHY SDK

### (installing an official release)

Things keep changing without notice from QHY, so take it with a grain of salt.

1. get the zip of a proper version of the SDK from the [current download page on QHY site](https://www.qhyccd.com/html/prepub/log_en.html). Likely, one of the latest Linux_64 packages *(see below for which)*;

2. unpack the zip in whichever directory;

3. open a shell and `cd` to that directory;

1. if up- or downgrading the SDK, run `sudo sh uninstall.sh` first *(not needed for a fresh installation)*

1. run `sudo sh install.sh`

One way to check that the installation succeeded, is to check for the presence of the library files with `ls /usr/local/lib/libqhy*`, and that camera firmware is correctly uploaded when connecting a camera on USB (call `dmesg -wH` and then connect the camera).

Other ways are trying to compile test applications in <path-to>`/sdk_linux64_XX.XX.XX/usr/local/testapp/`, and finally try to connect to a camera using the QHYccd class in Matlab.

### adding 21.03.30, unofficial, to 21.03.13 [*superseded by subsequent versions; no more recommended*]

Extra steps after the preceding ones:

5. get the new shared library file from
  [here](https://drive.google.com/file/d/1VnpejKukQmjZu3i65bJAoKZpt0li4ySs/view?usp=sharing)
  and store it somewhere

6. open a shell and run:

        sudo cp <somewhere>/libqhyccd.so.21.3.30.13 /usr/local/lib
        cd /usr/local/lib
        sudo ln -sf libqhyccd.so.21.3.30.13 libqhyccd.so.20
        sudo ln -sf libqhyccd.so.20 libqhyccd.so

## Later versions tested:

* 21.08.14 _[Log: add sensor status checking]_ --> **tested**, cameras hang about 1 time in 2.
* 21.08.05 _[Log: Disable device reset option when use linux by default]_ hohoho (not tested)
* 21.07.16 _[Log: update old camera memory issue during disconnection in LINUX]_ **tested, the stablest I've found so far**
* 21.06.25 _[Log: Fixed multiple cameras stop live mode bug in Linux]_ oh! (not tested, or did I?)
* 21.03.13 _[Log: Stability update]_ + private 21.03.30 patch: **tested** Maybe one hang in 10 calls
* 21.02.01 _[Log: Fixed: cannot get frame continuously under Linux]_ **tested**, impossible to shoot live more than once

Versions older than them had serious issues with live acquisition, or more odd crashes.

## Versions of the SDK supported

Keep in mind that our matlab toolbox does not support *just any* version of the sdk out of the box. So far any new version published needed review from our side, and some adjustments in our code, notably adapting the header
files needed by `loadlibrary`. The versions which our toolboks knows how to work with are, as of now:

- 21.10.12
- 21.08.14
- 21.08.05
- 21.07.16
- 21.3.30 (unofficial)
- 21.03.13
- 21.02.01
- 20.08.26
- 20.06.26
- V20200219

In addition the toolbox should be still able to work with installations from older .deb packages produced
by James Fidell in the beginning of 2020 (versions 6.0.x), though they are no more relevant at this stage, and possibly with some even older version.

Older ramblings on this pain are in [this file](OlderInstallingRamblings.md).