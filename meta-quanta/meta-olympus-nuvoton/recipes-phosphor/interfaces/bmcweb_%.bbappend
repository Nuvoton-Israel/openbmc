FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://0003-Redfish-Add-power-metrics-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0005-bmcweb-chassis-add-indicatorLED-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0014-add-config-to-config-virtual-media-buffer-size.patch"
SRC_URI_append_olympus-nuvoton = " file://0015-redfish-log-service-corrects-odata-id-of-bmc-journal.patch"
SRC_URI_append_olympus-nuvoton = " file://0016-manager-do-not-update-value-if-string-is-empty.patch"

# Enable CPU Log and Raw PECI support
EXTRA_OEMESON_append = " -Dredfish-cpu-log=enabled"
EXTRA_OEMESON_append = " -Dredfish-raw-peci=enabled"

# Enable Redfish BMC Journal support
EXTRA_OEMESON_append = " -Dredfish-bmc-journal=enabled"

# Enable DBUS log service
#EXTRA_OEMESON_append = " -Dredfish-dbus-log=enabled"

# Enable TFTP
EXTRA_OEMESON_append = " -Dinsecure-tftp-update=enabled"

# Increase body limit for BIOS FW
EXTRA_OEMESON_append = " -Dhttp-body-limit=35"

# Enable Redfish DUMP log service
EXTRA_OEMESON_append = " -Dredfish-dump-log=enabled"

# Buffer size for virtual media
EXTRA_OEMESON_append = " -Dvm-buffer-size=3"
