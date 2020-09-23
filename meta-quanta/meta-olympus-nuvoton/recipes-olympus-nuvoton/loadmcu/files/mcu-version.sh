#!/bin/sh

sleep 1

# get mcu firmware version
version=$(i2ctransfer -f -y 13 w2@0x70 0x01 0x30 r2)

# parse mcu firmware major revision
major=`echo $version | awk '{print$2}'`

# parse mcu firmware minor revision
minor=`echo $version | awk '{print$1}'`

version="V`echo $((major))`.`echo $((minor))`"
echo $version
echo "VERSION_ID=$version" > /usr/share/phosphor-bmc-code-mgmt/mcu-release
