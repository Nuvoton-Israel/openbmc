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
             file://mcu-update.sh \
             file://mcu-update.service \
           "
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git/"

do_install_append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mcu-update.sh ${D}${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mcu-update.service ${D}${systemd_system_unitdir}
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE_${PN} = "mcu-update.service"
