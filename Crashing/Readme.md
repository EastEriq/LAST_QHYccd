In this folder are stored scripts which should cause a sure crash of matlab by means of QHY
SDK calls. They are here for reference, and eventual stability tests with different
versions of the SDK.

Strangely the moment I'm about to test them, they crash or not, erratically, and possibly
depending on the amount of DebugOutput, or pauses between invocations -- which
smell of race conditions in the usb communication under the hood, perhaps.

The current version tested is sdk_linux64_21.03.13 + libqhyccd.so.21.3.30.13.

To run, it is convenient to start matlab with

`addpath LAST_Handle LAST_QHYccd/ LAST_QHYccd/Crashing`

