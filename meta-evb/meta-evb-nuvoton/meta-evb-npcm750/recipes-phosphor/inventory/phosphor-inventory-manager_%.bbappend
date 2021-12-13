FILESEXTRAPATHS_prepend_evb-npcm750 := "${THISDIR}/${PN}:"
PACKAGECONFIG_append_evb-npcm750 = " associations"

SRC_URI_append_evb-npcm750 = " file://associations.json"

do_install_append_evb-npcm750() {
    install -d ${D}${base_datadir}
    install -m 0755 ${WORKDIR}/associations.json ${D}${base_datadir}/associations.json
}
