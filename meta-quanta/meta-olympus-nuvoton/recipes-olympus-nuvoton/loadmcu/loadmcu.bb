FILESEXTRAPATHS_prepend := "${THISDIR}:"
DESCRIPTION = "MCU F/W Programmer"
PR = "r1"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

inherit systemd
inherit obmc-phosphor-systemd
inherit autotools pkgconfig

DEPENDS += "systemd"
DEPENDS += "autoconf-archive-native"
RDEPENDS_${PN} += "bash"

SRC_URI += " git://github.com/Nuvoton-Israel/loadmcu.git \
             file://mcu-update.service \
             file://mcu-version.sh \
             file://mcu-version@.service \
           "
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git/"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "mcu-update.service mcu-version@.service"
SYSTEMD_SERVICE_${PN} += "mcu-version@13.service"

do_install_append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mcu-version.sh ${D}${bindir}/
}
