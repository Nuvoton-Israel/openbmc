FILESEXTRAPATHS:append := "${THISDIR}/files:"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd"
RDEPENDS:${PN} += "libsystemd"
RDEPENDS:${PN} += "bash"

SRC_URI += "file://usb_network_rndis.sh \
           file://usb_network_rndis.service \
           file://00-bmc-usb0-rndis.network \
           file://10-bmc-usb-rndis.link"

S = "${UNPACKDIR}"


do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/usb_network_rndis.sh ${D}/${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/usb_network_rndis.service ${D}${systemd_unitdir}/system

    install -d ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/00-bmc-usb0-rndis.network ${D}${sysconfdir}/systemd/network

    install -d ${D}${base_libdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/10-bmc-usb-rndis.link ${D}${base_libdir}/systemd/network
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "usb_network_rndis.service"
FILES:${PN} += "${sysconfdir}/systemd/network/00-bmc-usb0-rndis.network"
FILES:${PN} += "${base_libdir}/systemd/network/10-bmc-usb-rndis.link"

inherit allarch systemd
