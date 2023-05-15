FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://power-config-host0.json"

FILES:${PN}:append:evb-npcm750 = " ${datadir}/x86-power-control/power-config-host0.json"

do_install:append:evb-npcm750() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 -D ${WORKDIR}/power-config-host0.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}
