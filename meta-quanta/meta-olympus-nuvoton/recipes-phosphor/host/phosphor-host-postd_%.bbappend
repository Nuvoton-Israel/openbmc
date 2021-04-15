FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://bios_defs.json"

SNOOP_DEVICE = "npcm7xx-lpc-bpc0"

DEPENDS += "nlohmann-json"

do_install_append() {
        install -d ${D}${sysconfdir}/default/obmc/bios/
        install -m 0644 ${WORKDIR}/bios_defs.json ${D}/${sysconfdir}/default/obmc/bios/
}
