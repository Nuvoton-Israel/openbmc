FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://baseboard.fru.bin \
    file://nuvoton_npcm8xx_evb.json \
    "

do_install:append () {
    mkdir -p ${D}/etc/fru
    install -m 0444 ${UNPACKDIR}/baseboard.fru.bin ${D}/etc/fru
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${UNPACKDIR}/nuvoton_npcm8xx_evb.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton_npcm8xx_evb.json
}
