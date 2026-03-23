SUMMARY = "Cerberus utility for NPCM8XX (Arbel) devices"
DESCRIPTION = "Primary bootloader for NPCM8XX (Arbel) devices"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILENAME = "cerberus_utility_${PV}"

S = "${UNPACKDIR}/sources"


SRC_URI = "file://${FILENAME};name=bin"
SRC_URI[bin.sha256sum] = "36d482fa6b89f28de89f1de673f78293794b71d91d0d108a60e5b94cdb0c5fcf"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${UNPACKDIR}/${FILENAME} ${D}/${sbindir}/cerberus_utility
}