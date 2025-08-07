FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://lsusb.cfg"
SRC_URI:append = " file://timeout.cfg"
SRC_URI:append = " file://dd.cfg"
SRC_URI:append = " file://head.cfg"
SRC_URI:append = " file://ifconfig.cfg"
SRC_URI:append = " file://taskset.cfg"
