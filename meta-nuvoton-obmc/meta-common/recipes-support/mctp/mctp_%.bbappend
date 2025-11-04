FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

# Support mctp over pcie vdm
# SRCREV = "4a4b7a5af184febc681da4af4341a644e7eb7d35"
# SRC_URI = "git://github.com/khangng-ampere/mctp;branch=main;protocol=https"
# SRC_URI:append:nuvoton = " file://0001-mctpd-Support-mctp-over-pcie-vdm.patch"

#SRC_URI:append:nuvoton = " file://0001-Add-mctp-i2c-discovery-command.patch"

DEPENDS += "i2c-tools"
