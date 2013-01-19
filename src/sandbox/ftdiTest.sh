#!/bin/sh
#
# Report information about the FTDI USB serial driver
# Credit goes to this fourm http://arduino.cc/forum/index.php/topic,3345.0.html
# Use to test if the ftdi chip is not showing up under mac

echo "[Extensions]"
for KEXT in `ls -d /System/Library/Extensions/*FTDI*` ; do
    echo $KEXT
    find "$KEXT" -name InfoPlist.strings -exec cat {} \;
done

echo "[Devices]"
ls /dev/*usb*

echo "[System logs]"
bzgrep FTDI /var/log/system.log*
