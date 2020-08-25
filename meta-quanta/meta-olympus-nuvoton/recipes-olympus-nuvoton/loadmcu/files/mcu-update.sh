#!/bin/sh

echo "MCU F/W Start Programming"

./usr/bin/loadmcu -d /dev/mcu0 -s /tmp/image-mcu

echo "MCU F/W End Programming"
