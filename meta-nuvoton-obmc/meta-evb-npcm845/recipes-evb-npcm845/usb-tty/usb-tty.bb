FILESEXTRAPATHS:append := "${THISDIR}/files:"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd"
RDEPENDS:${PN} += "libsystemd"
RDEPENDS:${PN} += "bash"

SRC_URI += "file://usb_tty.sh \
           file://usb_tty.service \
           file://serial-getty-ttyGS0.conf"

S = "${UNPACKDIR}/sources"


do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/usb_tty.sh ${D}/${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/usb_tty.service ${D}${systemd_unitdir}/system

    install -d ${D}${systemd_unitdir}/system/serial-getty@ttyGS0.service.d
    install -m 0644 ${UNPACKDIR}/serial-getty-ttyGS0.conf \
        ${D}${systemd_unitdir}/system/serial-getty@ttyGS0.service.d/10-no-tty-reset.conf
}

FILES:${PN} += "${systemd_unitdir}/system/serial-getty@ttyGS0.service.d"

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "usb_tty.service"

inherit allarch systemd
