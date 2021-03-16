# Installation of QHY SDK

(Status of 16/3/2021)

Things keep changing without notice from QHY, so take it with a grain of salt.

1. get the zip of a proper version of the SDK from the [current download page on QHY site](https://www.qhyccd.com/html/prepub/log_en.html). Likely, one of the latest Linux_64 packages *(see below for which)*;

2. unpack the zip in whichever directory;

3. open a shell and `cd` to that directory;

1. if up- or downgrading the SDK, run `sudo sh uninstall.sh` first *(not needed for a fresh installation)*

1. run `sudo sh install.sh`

One way to check that the installation succeeded, is to check for the presence of the library files with `ls /usr/local/lib/libqhy*`, and that camera firmware is correctly uploaded when connecting a camera on USB (call `dmesg -wH` and then connect the camera).

Other ways are trying to compile test applications in <path-to>`/sdk_linux64_XX.XX.XX/usr/local/testapp/`, and finally try to connect to a camera using the QHYccd class in Matlab.

## Versions of the SDK supported

Keep in mind that our matlab toolbox does not support *just any* version of the sdk out of the box. So far any new version published needed review from our side, and some adjustments in our code, notably adapting the header
files needed by`loadlibrary`. The versions which our toolboks knows how to work with are, as of now:

- 21.03.13
- 21.02.01
- 20.08.26
- 20.06.26
- V20200219

In addition the toolbox should be still able to work with installations from older .deb packages produced
by James Fidell in the beginning of 2020 (versions 6.0.x), though they are no more relevant at this stage, and possibly with some even older version.

Older ramblings on this pain are in [this file](OlderInstallingRamblings.md).