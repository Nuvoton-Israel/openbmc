SUMMARY = "Set NPCM500 JTAG strap pins (JEN1#..JEN4#) from Arbel GPIOs"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = "file://npcm500-jen.sh"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

RDEPENDS:${PN} += "libgpiod-tools"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/npcm500-jen.sh ${D}${bindir}/npcm500-jen
}
