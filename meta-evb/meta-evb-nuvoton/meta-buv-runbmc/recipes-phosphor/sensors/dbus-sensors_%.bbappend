FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " \
    file://0002-intrusionsensor-Add-polling-event-status-by-sysfs.patch \
    "
