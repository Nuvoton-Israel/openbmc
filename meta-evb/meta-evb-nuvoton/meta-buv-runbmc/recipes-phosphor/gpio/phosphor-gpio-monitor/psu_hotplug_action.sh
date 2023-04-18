#!/bin/bash

echo "reload sensor config $1"

# 1: Entity, 2: Invenotry Stop PSU0 hwmon, 3: Invenotry Start PSU0 hwmon
if [ $1 = "1" ]; then
    # stop service
    systemctl stop xyz.openbmc_project.psusensor.service
    sleep 0.5s

    # start service
    systemctl start xyz.openbmc_project.psusensor.service
    sleep 0.5s
fi

if [ $1 = "2" ]; then
    # stop service
    start_hwmon.sh stop %p /ahb/apb/i2c@8b000/ina219@40
    sleep 0.5s
fi

if [ $1 = "3" ]; then
    # start service
    start_hwmon.sh start %p /ahb/apb/i2c@8b000/ina219@40
    sleep 0.5s
fi