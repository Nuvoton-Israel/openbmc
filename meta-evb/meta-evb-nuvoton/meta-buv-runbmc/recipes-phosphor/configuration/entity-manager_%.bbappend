FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI_append_buv-runbmc = " file://F0B_BMC_BMC.json"

FILES_${PN}_append_buv-runbmc = " \
    ${datadir}/entity-manager/F0B_BMC_BMC.json"

do_install_append_buv-runbmc() {
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${WORKDIR}/F0B_BMC_BMC.json \
        ${D}${datadir}/entity-manager/configurations/F0B_BMC_BMC.json
}
