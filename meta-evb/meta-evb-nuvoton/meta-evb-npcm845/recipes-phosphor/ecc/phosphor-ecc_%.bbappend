FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

# reload service files
SRC_URI:append:evb-npcm845 = " \
    file://phosphor-ecc.service \
    "

SYSTEMD_SERVICE:${PN}:append:evb-npcm845 = " \
    phosphor-ecc.service \
    "

do_install:append:evb-npcm845() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ecc.service \
        ${D}${systemd_unitdir}/system
}