FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI += " file://default \
             file://host_eid \
             file://0001-support-sensor-reading.patch "

CONFFILES_${PN} = "${sysconfdir}/default/pldmd"
FILES_${PN} += "${datadir}/host_eid"

do_install_append() {
	install -d ${D}${sysconfdir}/default
	install -m 0644 ${WORKDIR}/default ${D}${sysconfdir}/default/pldmd
	install -d ${D}${datadir}/pldm
	install -m 0644 -D ${WORKDIR}/host_eid ${D}${datadir}/pldm/host_eid
}