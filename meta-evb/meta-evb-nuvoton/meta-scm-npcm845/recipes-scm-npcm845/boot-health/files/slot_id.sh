#!/bin/sh
set -e


# the BMC ethernet interface
eth="eth0"

# parsing mac and ip address from ifconfig
ifdata=$(ifconfig ${eth})
mac=$(echo $ifdata |grep -o "HWaddr [0-9:A-F]\+")
slot_id=$(echo $mac|grep -o [0-9A-F]*$)
ipaddr=$(echo $ifdata |grep -o "inet addr:[0-9.]\+")
ip_end=$(echo $ipaddr | grep -o [0-9A-F]*$)
ip_oct=$(printf "%x\n" $ip_end)


if [ "${slot_id}" == "${ip_oct}" ]; then
  echo "slot ID matches rule."
  exit 0
fi

# write SEL for mismatch case
busctl call `mapper get-service /xyz/openbmc_project/Logging/IPMI` /xyz/openbmc_project/Logging/IPMI xyz.openbmc_project.Logging.IPMI IpmiSelAdd ssaybq "slot ID mismatch" "/xyz/openbmc_project/sensors/oem_health/slot_id" 3 173 0 0 true 0x2000
echo "slot ID mismatches rule."
