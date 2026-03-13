FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://baseboard.fru.bin \
    file://nuvoton_npcm8xx_evb.json \
    file://nuvoton_npcm400_evb_usb.json \
    file://nuvoton_npcm400_evb_i2c.json \
    file://0001-schemas-Describe-MCTP-USB-targets.patch \
    "

do_install:append () {
    mkdir -p ${D}/etc/fru
    rm -rf ${D}${datadir}/entity-manager/configurations/*
    install -m 0444 ${UNPACKDIR}/baseboard.fru.bin ${D}/etc/fru
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${UNPACKDIR}/nuvoton_npcm8xx_evb.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton/npcm8xx_evb.json
    install -m 0644 -D ${UNPACKDIR}/nuvoton_npcm400_evb_usb.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton/npcm400_evb_usb.json
    install -m 0644 -D ${UNPACKDIR}/nuvoton_npcm400_evb_i2c.json \
        ${D}${datadir}/entity-manager/configurations/nuvoton/npcm400_evb_i2c.json
}
