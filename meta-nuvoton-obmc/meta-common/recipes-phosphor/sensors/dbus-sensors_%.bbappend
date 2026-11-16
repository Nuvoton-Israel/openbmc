FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-mctp-Add-USB-hot-plug-support-with-static-EID-assign.patch"
SRC_URI:append = " file://0002-mctp-Resolve-USB-root-hub-positions-on-the-NPCM845.patch"
