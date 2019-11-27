FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://bios_defs.json"
SRC_URI += "file://0001-main-add-feature-for-updating-BootProgress-and-Opera.patch"

SNOOP_DEVICE = "npcm7xx-lpc-bpc0"

DEPENDS += "nlohmann-json"

do_install() {
        oe_runmake install DESTDIR=${D}

        install -d ${D}${sysconfdir}/default/obmc/bios/
        install -m 0644 ${WORKDIR}/bios_defs.json ${D}/${sysconfdir}/default/obmc/bios/
}
