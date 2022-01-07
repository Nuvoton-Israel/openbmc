FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append:olympus-nuvoton = " file://0003-Redfish-Add-power-metrics-support.patch"
SRC_URI:append:olympus-nuvoton = " file://0005-bmcweb-chassis-add-indicatorLED-support.patch"
SRC_URI:append:olympus-nuvoton = " file://0018-redfish-log_services-fix-createDump-functionality.patch"
SRC_URI:append:olympus-nuvoton = " file://0001-redfish-update_service-fix-fwUpdateErrorMatcher-cann.patch"

# Enable CPU Log support
EXTRA_OEMESON:append:olympus-nuvoton = " -Dredfish-cpu-log=enabled"

# Enable Redfish BMC Journal support
EXTRA_OEMESON:append:olympus-nuvoton = " -Dredfish-bmc-journal=enabled"

# Enable DBUS log service
#EXTRA_OEMESON:append = " -Dredfish-dbus-log=enabled"

# Enable TFTP
EXTRA_OEMESON:append:olympus-nuvoton = " -Dinsecure-tftp-update=enabled"

# Increase body limit for BIOS FW
EXTRA_OEMESON:append:olympus-nuvoton = " -Dhttp-body-limit=35"

# Enable Redfish DUMP log service
EXTRA_OEMESON:append:olympus-nuvoton = " -Dredfish-dump-log=enabled"

# Buffer size for virtual media
#EXTRA_OEMESON:append = " -Dvm-buffer-size=3"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append:olympus-nuvoton = " -Drest=enabled"

# Enable debug message
#EXTRA_OEMESON:append:olympus-nuvoton = " -Dbmcweb-logging=enabled"
