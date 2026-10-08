SUMMARY = "OCP secure firmware recovery image-push tool over USB"
DESCRIPTION = "Pushes recovery images into an OCP recovery device over USB EP0 \
control transfers using USBDEVFS_CONTROL."
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://usb_ocp_recovery.c file://caliptra-recovery-usb.sh"
S = "${WORKDIR}/${BPN}"
UNPACKDIR = "${S}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o usb_ocp_recovery ${UNPACKDIR}/usb_ocp_recovery.c
}

do_install() {
    install -D -m 0755 ${B}/usb_ocp_recovery ${D}${bindir}/usb_ocp_recovery
    install -m 0755 ${UNPACKDIR}/caliptra-recovery-usb.sh ${D}${bindir}/caliptra-recovery-usb.sh
}
