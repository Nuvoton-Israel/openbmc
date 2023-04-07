FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

#SRC_URI:append:buv-runbmc = " file://0001-intrusionsensor-Add-polling-event-status-by-sysfs.patch"
SRC_URI:append:buv-runbmc = " file://0001-psusensor-rename-device-type-IPSPS-to-IPSPS1.patch"
