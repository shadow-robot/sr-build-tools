This document 

Edit `build-image.sh` and change `BASEDIR` and other top-level variables
to suite your requirements. Then run the build.

    sudo ./build-image.sh

This will take a long time, so I suggest you start this running before you go
to bed.

## References

  * <https://wiki.ubuntu.com/ARM/RaspberryPi>
  * <https://wiki.ubuntu.com/ARM/BuildEABIChroot>
  * <https://0xstubs.org/stock-debian-jessie-on-the-raspberry-pi-2/>
  * <http://omxplayer.sconde.net/>
  * <https://github.com/bavison/arm-mem/>
    * <https://www.raspberrypi.org/forums/viewtopic.php?t=47832&p=403191>
  * <https://www.raspberrypi.org/documentation/configuration/config-txt.md>
  * [Peter Chubb. "SD cards and filesystems for embedded systems". Linux.conf.au.](http://mirror.linux.org.au/pub/linux.conf.au/2015/Case_Room_2/Friday/SD_Cards_and_filesystems_for_Embedded_Systems.webm)

## ODROID C1

We'd like to support the ODROID C1 too. This looks useful:

  * http://odroid.com/dokuwiki/doku.php?id=en:c1_ubuntu_minimal
  * https://github.com/umiddelb/armhf/wiki/Install-Ubuntu-Core-14.04-on-ARMv7-%28ODROID-C1%29
