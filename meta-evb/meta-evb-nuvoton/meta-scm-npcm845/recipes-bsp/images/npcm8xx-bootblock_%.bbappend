FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-Clean-the-reset-control-bit-of-SIOX1-2.patch"
