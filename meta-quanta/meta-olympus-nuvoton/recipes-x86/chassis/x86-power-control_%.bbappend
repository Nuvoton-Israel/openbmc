FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://power-config-host0.json"
SRC_URI_append_olympus-nuvoton = " file://0001-support-host-boot-progress.patch"

FILES_${PN} += " ${datadir}/x86-power-control/power-config-host0.json \"

do_install_append_olympus-nuvoton() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 -D ${WORKDIR}/power-config-host0.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}
