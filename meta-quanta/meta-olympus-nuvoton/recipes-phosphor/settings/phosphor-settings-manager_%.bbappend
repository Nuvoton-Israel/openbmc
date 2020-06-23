FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://chassis-cap.override.yml"
SRC_URI_append_olympus-nuvoton = " file://sol-default.override.yml"
