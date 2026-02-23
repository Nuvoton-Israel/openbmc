FILESEXTRAPATHS:append := "${THISDIR}/files:"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd"
RDEPENDS:${PN} += "libsystemd"
RDEPENDS:${PN} += "dnsmasq"

SRC_URI += "file://usb_network.sh \
           file://usb_network.service \
           file://00-bmc-usb0.network \
           file://usb0-dhcp.conf"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/usb_network.sh ${D}/${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/usb_network.service ${D}${systemd_unitdir}/system

    install -d ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${UNPACKDIR}/00-bmc-usb0.network ${D}${sysconfdir}/systemd/network

    install -d ${D}${sysconfdir}/dnsmasq.d/
    install -m 0644 ${UNPACKDIR}/usb0-dhcp.conf ${D}${sysconfdir}/dnsmasq.d/
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "usb_network.service"
FILES:${PN} += "${sysconfdir}/systemd/network/00-bmc-usb0.network"
FILES:${PN} += "${sysconfdir}/dnsmasq.d/usb0-dhcp.conf"

inherit allarch systemd
