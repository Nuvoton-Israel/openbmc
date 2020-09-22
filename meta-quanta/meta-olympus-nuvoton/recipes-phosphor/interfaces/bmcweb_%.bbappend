FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://0003-Redfish-Add-power-metrics-support.patch"
#SRC_URI_append_olympus-nuvoton = " file://0004-bmcweb-sensors-get-sensor-list-also-form-path-with-s.patch"
SRC_URI_append_olympus-nuvoton = " file://0005-bmcweb-chassis-add-indicatorLED-support.patch"
#SRC_URI_append_olympus-nuvoton = " file://0006-bmcweb-get-cpu-and-dimm-info-from-prettyname.patch"

SRC_URI_append_olympus-nuvoton = " file://0001-redfish-cpudimm-fix-cannot-prsent-totalcores.patch"
SRC_URI_append_olympus-nuvoton = " file://0010-bmcweb-fix-segmentation-fault-in-update-service.patch"

# Enable CPU Log and Raw PECI support
EXTRA_OECMAKE += "-DBMCWEB_ENABLE_REDFISH_CPU_LOG=ON"
EXTRA_OECMAKE += "-DBMCWEB_ENABLE_REDFISH_RAW_PECI=ON"

# Enable Redfish BMC Journal support
# EXTRA_OECMAKE += "-DBMCWEB_ENABLE_REDFISH_BMC_JOURNAL=ON"

# Enable DBUS log service
EXTRA_OECMAKE += "-DBMCWEB_ENABLE_REDFISH_DBUS_LOG_ENTRIES=ON"

# Enable TFTP
EXTRA_OECMAKE += "-DBMCWEB_INSECURE_ENABLE_REDFISH_FW_TFTP_UPDATE=ON"

# Increase body limit for BIOS FW
EXTRA_OECMAKE += "-DBMCWEB_HTTP_REQ_BODY_LIMIT_MB=35"
