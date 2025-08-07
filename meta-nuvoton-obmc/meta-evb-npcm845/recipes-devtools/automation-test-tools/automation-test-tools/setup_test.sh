#!/bin/sh
mkdir /tmp/log
echo fff02000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/unbind
devmem 0xf0800268 32 0x6ef6
gpioset 2 6=1

echo slave-24c02 0x1064 > /sys/bus/i2c/devices/i2c-1/new_device
i2c_slave_rw -d /dev/i2c-2 -a 0x64 -i 100 1
echo 0x1064 > /sys/bus/i2c/devices/i2c-1/delete_device
