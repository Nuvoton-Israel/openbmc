FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-mctpreactor-Support-configuration-for-USB-MCTP-devic.patch"
SRC_URI:append = " file://0002-mctp-Add-USB-hot-plug-support-with-static-EID-assign.patch"
