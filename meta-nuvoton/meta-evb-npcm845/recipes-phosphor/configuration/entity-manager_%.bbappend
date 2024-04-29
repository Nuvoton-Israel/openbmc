FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://blacklist.json \
    file://baseboard.fru.bin \
    file://nuvoton_npcm8xx_evb.json \
    "

do_install:append () {
    install -m 0644 -D ${WORKDIR}/blacklist.json ${D}${datadir}/${PN}/blacklist.json
    mkdir -p ${D}/etc/fru
    install -m 0444 ${WORKDIR}/baseboard.fru.bin ${D}/etc/fru
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${WORKDIR}/nuvoton_npcm8xx_evb.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton_npcm8xx_evb.json
}
