FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://Add-Openbmc-oem-whitelist.patch"
