FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRCREV := "5235d9640276f2421b5fcff1d5a356101fd301e6"

SRC_URI_append_olympus-nuvoton = " file://0003-Redfish-Add-power-metrics-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0005-bmcweb-chassis-add-indicatorLED-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0010-bmcweb-fix-segmentation-fault-in-update-service.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-redifsh-logservice-fix-duplicate-res-end.patch"
SRC_URI_append_olympus-nuvoton = " file://0013-systems-fix-Members-odata.count-is-incorrect-even-Me.patch"

# Enable CPU Log and Raw PECI support
EXTRA_OEMESON_append = " -Dredfish-cpu-log=enabled"
EXTRA_OEMESON_append = " -Dredfish-raw-peci=enabled"

# Enable Redfish BMC Journal support
# EXTRA_OEMESON_append = " -Dredfish-bmc-journal=enabled"

# Enable DBUS log service
EXTRA_OEMESON_append = " -Dredfish-dbus-log=enabled"

# Enable TFTP
EXTRA_OEMESON_append = " -Dinsecure-tftp-update=enabled"

# Increase body limit for BIOS FW
EXTRA_OEMESON_append = " -Dhttp-body-limit=35"

# Enable Redfish DUMP log service
EXTRA_OEMESON_append = " -Dredfish-dump-log=enabled"
