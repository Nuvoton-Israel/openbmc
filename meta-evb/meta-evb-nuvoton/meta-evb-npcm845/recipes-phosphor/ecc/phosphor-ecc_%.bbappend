FILESEXTRAPATHS_prepend_evb-npcm845 := "${THISDIR}/${PN}:"

# reload service files
SRC_URI_append_evb-npcm845 = " \
    file://phosphor-ecc.service \
    "

SYSTEMD_SERVICE_${PN}_append_evb-npcm845 = " \
    phosphor-ecc.service \
    "

do_install_append_evb-npcm845() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ecc.service \
        ${D}${systemd_unitdir}/system
}