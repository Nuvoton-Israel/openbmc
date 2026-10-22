FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# The OBMF distro (df-obmf) reaches the NPCM400 MCTP I2C device through the
# OBMF I2C channel (i2c-27, mctpi2c27) and probes it unconditionally.
NPCM400_I2C_JSON = "nuvoton_npcm400_evb_i2c.json"
NPCM400_I2C_JSON:df-obmf = "nuvoton_npcm400_evb_i2c-obmf.json"

# The OBMF distro also reaches SMC2 as an MCTP I3C target on the OBMF I3C
# channel (i3c-2, mctpi3c2).
NPCM400_I3C_JSON = ""
NPCM400_I3C_JSON:df-obmf = "npcm400_evb_i3c_obmf.json"
SRC_URI:append:df-obmf = " file://${NPCM400_I3C_JSON}"

SRC_URI:append = " \
    file://baseboard.fru.bin \
    file://nuvoton_npcm8xx_evb.json \
    file://nuvoton_npcm400_evb_usb.json \
    file://${NPCM400_I2C_JSON} \
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
    install -m 0644 -D ${UNPACKDIR}/${NPCM400_I2C_JSON} \
        ${D}${datadir}/entity-manager/configurations/nuvoton/npcm400_evb_i2c.json
    if [ -n "${NPCM400_I3C_JSON}" ]; then
        install -m 0644 -D ${UNPACKDIR}/${NPCM400_I3C_JSON} \
            ${D}${datadir}/entity-manager/configurations/nuvoton/${NPCM400_I3C_JSON}
    fi
}
