FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://sol-default.override.yml"
SRC_URI:append = " file://chassis-poh.override.yml"
