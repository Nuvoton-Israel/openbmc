FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " \
    file://0001-Add-more-PSU-devices-support.patch \
    "
