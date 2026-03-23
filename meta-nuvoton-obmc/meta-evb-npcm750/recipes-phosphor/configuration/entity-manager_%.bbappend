FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://nuvoton_npcm7xx_evb.json"
SRC_URI:append = " file://baseboard.fru.bin"
SRC_URI:append = " file://blacklist.json"

do_install:append() {
    rm -rf ${D}${datadir}/entity-manager/configurations/*
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${UNPACKDIR}/nuvoton_npcm7xx_evb.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton/nuvoton_npcm7xx_evb.json
    install -m 0644 -D ${UNPACKDIR}/blacklist.json\
        ${D}${datadir}/entity-manager/blacklist.json
    mkdir -p ${D}/etc/fru
    install -m 0444 ${UNPACKDIR}/baseboard.fru.bin ${D}/etc/fru
}
