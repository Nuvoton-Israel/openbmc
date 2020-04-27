FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " \
    file://0001-Support-for-NameServers-StaticNameServers.patch \
    file://0003-Redfish-Add-power-metrics-support.patch \
    file://0004-bmcweb-sensors-get-sensor-list-also-form-path-with-s.patch \
    file://0005-bmcweb-chassis-add-indicatorLED-support.patch \
    file://0006-bmcweb-get-cpu-and-dimm-info-from-prettyname.patch \
    file://0008-log_services-fix-Severity-Empty-string-found-issue-w.patch \
"

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
