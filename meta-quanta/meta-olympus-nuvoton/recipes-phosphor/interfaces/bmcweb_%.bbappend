inherit entity-utils

FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/${PN}:"

#SRC_URI:append:olympus-nuvoton = " file://0001-Handle-now-allow-execption-in-account-service.patch"
#SRC_URI:append:olympus-nuvoton = " file://0002-Redfish-Add-power-metrics-support.patch"
#SRC_URI:append:olympus-nuvoton = " file://0003-Create-new-user-without-SSH-group.patch"
#SRC_URI:append:olympus-nuvoton = " file://0004-bmcweb-chassis-add-indicatorLED-support.patch"
#SRC_URI:append:olympus-nuvoton = " file://0005-redfish-log_services-fix-createDump-functionality.patch"

# Enable CPU Log support
EXTRA_OEMESON:append:olympus-nuvoton = " -Dredfish-cpu-log=enabled"

# Enable Redfish DBUS log/Journal support
EXTRA_OEMESON:append:olympus-nuvoton = " ${@entity_enabled(d, '-Dredfish-bmc-journal=enabled', '-Dredfish-dbus-log=enabled')}"

# Increase body limit for BIOS FW
EXTRA_OEMESON:append:olympus-nuvoton = " -Dhttp-body-limit=65"

# Enable Redfish DUMP log service
EXTRA_OEMESON:append:olympus-nuvoton = " -Dredfish-dump-log=enabled"

# Buffer size for virtual media
#EXTRA_OEMESON:append = " -Dvm-buffer-size=3"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append:olympus-nuvoton = " -Drest=enabled"

# Enable debug message
#EXTRA_OEMESON:append:olympus-nuvoton = " -Dbmcweb-logging=enabled"
