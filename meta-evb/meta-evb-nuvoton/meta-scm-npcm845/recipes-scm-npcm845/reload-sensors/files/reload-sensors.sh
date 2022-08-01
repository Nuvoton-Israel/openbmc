#!/bin/bash

sleep 3s
echo f0081000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/unbind
echo f008a000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/unbind
sleep 1s
echo f0081000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/bind
echo f008a000.i2c > /sys/bus/platform/drivers/nuvoton-i2c/bind
sleep 1s

systemctl restart xyz.openbmc_project.hwmontempsensor.service
sleep 0.5s
systemctl restart xyz.openbmc_project.dimmsensor.service
sleep 0.5s
systemctl restart xyz.openbmc_project.nvmesensor.service
sleep 0.5s
