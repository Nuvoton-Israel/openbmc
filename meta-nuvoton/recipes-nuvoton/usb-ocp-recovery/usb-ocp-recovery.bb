SUMMARY = "OCP secure firmware recovery image-push tool over USB"
DESCRIPTION = "Pushes recovery images into an OCP recovery device over USB EP0 \
control transfers using USBDEVFS_CONTROL."
PR = "r2"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = "file://usb_ocp_recovery.c \
           file://caliptra-recovery-usb.sh \
           file://bench/caliptra_fw.bin \
           file://bench/soc_manifest.bin \
           file://bench/runtime-npcm500.bin \
           file://bench/NPCM5_pldm.bin \
           "
S = "${WORKDIR}/${BPN}"
UNPACKDIR = "${S}"

BENCH_FW_DIR = "${datadir}/usb-ocp-recovery"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o usb_ocp_recovery ${UNPACKDIR}/usb_ocp_recovery.c
}

do_install() {
    install -D -m 0755 ${B}/usb_ocp_recovery ${D}${bindir}/usb_ocp_recovery
    install -m 0755 ${UNPACKDIR}/caliptra-recovery-usb.sh ${D}${bindir}/caliptra-recovery-usb.sh

    install -d ${D}${BENCH_FW_DIR}
    install -m 0644 ${UNPACKDIR}/bench/caliptra_fw.bin ${D}${BENCH_FW_DIR}/caliptra_fw.bin
    install -m 0644 ${UNPACKDIR}/bench/soc_manifest.bin ${D}${BENCH_FW_DIR}/soc_manifest.bin
    install -m 0644 ${UNPACKDIR}/bench/runtime-npcm500.bin ${D}${BENCH_FW_DIR}/runtime-npcm500.bin
    install -m 0644 ${UNPACKDIR}/bench/NPCM5_pldm.bin ${D}${BENCH_FW_DIR}/NPCM5_pldm.bin
}

FILES:${PN} += "${BENCH_FW_DIR}"
