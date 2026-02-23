FILESEXTRAPATHS:append := "${THISDIR}/files:"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd"
RDEPENDS:${PN} += "libsystemd"
RDEPENDS:${PN} += "e2fsprogs-mke2fs"

SRC_URI += "file://usb_emmc_storage.sh \
           file://usb_emmc_storage.service \
           file://format_emmc.sh \
           file://mnt-emmc.mount"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/usb_emmc_storage.sh ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/format_emmc.sh ${D}/${sbindir}

    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/usb_emmc_storage.service ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/mnt-emmc.mount ${D}${systemd_unitdir}/system
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "usb_emmc_storage.service mnt-emmc.mount"

inherit allarch systemd
