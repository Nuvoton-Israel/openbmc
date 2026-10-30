SUMMARY = "USB gadget link from a Satellite BMC to an Aggregator BMC"
DESCRIPTION = "Composite USB gadget on udc0 carrying CDC ECM (Redfish)"
FILESEXTRAPATHS:append := "${THISDIR}/files:"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd"
RDEPENDS:${PN} += "libsystemd"

SRC_URI += "file://usb_satellite_link.sh \
           file://usb_satellite_link.service \
           file://aggregator-host/00-bmc-satellite-host.network \
           file://aggregator-host/10-bmc-satellite-host.link \
           "

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/usb_satellite_link.sh ${D}${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/usb_satellite_link.service ${D}${systemd_unitdir}/system

    # Sample files for the Aggregator BMC (USB host side); not active on the satellite.
    install -d ${D}${datadir}/usb-satellite-link/aggregator-host
    install -m 0644 ${UNPACKDIR}/aggregator-host/00-bmc-satellite-host.network \
            ${D}${datadir}/usb-satellite-link/aggregator-host
    install -m 0644 ${UNPACKDIR}/aggregator-host/10-bmc-satellite-host.link \
            ${D}${datadir}/usb-satellite-link/aggregator-host
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "usb_satellite_link.service"
FILES:${PN} += "${datadir}/usb-satellite-link"

inherit allarch systemd
