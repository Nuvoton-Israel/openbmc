FILESEXTRAPATHS_prepend_evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI_append_evb-npcm845 = " file://ARBEL_EVB_BMC.json"

FILES_${PN}_append_evb-npcm845 = " \
    ${datadir}/entity-manager/ARBEL_EVB_BMC.json"

do_install_append_evb-npcm845() {
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${WORKDIR}/ARBEL_EVB_BMC.json \
        ${D}${datadir}/entity-manager/configurations/ARBEL_EVB_BMC.json
}
