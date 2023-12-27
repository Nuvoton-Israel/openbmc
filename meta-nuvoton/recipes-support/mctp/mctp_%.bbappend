FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

# Support mctp over pcie vdm
# SRCREV = "4a4b7a5af184febc681da4af4341a644e7eb7d35"
# SRC_URI = "git://github.com/khangng-ampere/mctp;branch=main;protocol=https"

SRC_URI:append:nuvoton = " file://0001-Add-mctp-discovery-command.patch"
SRC_URI:append:nuvoton = " file://mctpd.service"
SRC_URI:append:nuvoton = " file://mctp-config.sh"
# SRC_URI:append:nuvoton = " file://0001-mctpd-Support-mctp-over-pcie-vdm.patch"

DEPENDS += "i2c-tools"

FILES:${PN}:append:nuvoton = " ${bindir}/mctp-config.sh"
do_install:prepend:nuvoton () {
    install -Dm 0755 ${WORKDIR}/mctp-config.sh ${D}${bindir}/mctp-config.sh
    install -m 644 ${WORKDIR}/mctpd.service ${S}/conf/mctpd.service
}
