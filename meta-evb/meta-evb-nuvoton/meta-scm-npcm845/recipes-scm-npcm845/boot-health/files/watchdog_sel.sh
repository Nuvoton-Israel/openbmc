#!/bin/sh
set -e

INTCR2=0xf0800060
BOOTSTATUS=$(cat /sys/class/watchdog/watchdog0/bootstatus)

# watchdog boot status define please ref DTS, we used WDIOF_CARDRESET,
# WDIOF_EXTERN1 and WDIOF_EXTERN2, assume use WD1 as EXT1 (0x4)
val=$(( ${BOOTSTATUS} & 0x4 ))
echo "bootstatus: ${val}"

# write watchdog SEL
if [ "${val}" == "4" ]; then
  busctl call `mapper get-service /xyz/openbmc_project/Logging/IPMI` /xyz/openbmc_project/Logging/IPMI xyz.openbmc_project.Logging.IPMI IpmiSelAdd ssaybq "Hardware WDT expired" "/xyz/openbmc_project/sensors/oem_health/hw_watchdog" 3 163 0 0 true 0x2000
  echo "Detected watchdog triggered"
fi

# clear INTCR2
val=$(devmem ${INTCR2})
clr_val=$(( ${val} & 0x007FFFFF ))
echo "clear INTCR2 val: ${clr_val}"
devmem ${INTCR2} w ${clr_val}
