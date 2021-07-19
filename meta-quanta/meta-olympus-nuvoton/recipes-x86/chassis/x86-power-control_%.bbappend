FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"
inherit entity-utils

OLYMPUS_FILES = " \
    file://0001-support-host-boot-progress.patch \
    file://0002-add-support-chassis-on-off-target-files.patch \
    file://obmc-mapper.target \
    file://obmc-chassis-poweroff.target \
    file://obmc-chassis-poweron.target \
    "
SRC_URI_append_olympus-nuvoton = " file://power-config-host0.json"
SRC_URI_append_olympus-nuvoton = " ${@entity_enabled(d, '', '${OLYMPUS_FILES}')}"

OLYMPUS_TARGETS = " \
    obmc-mapper.target \
    obmc-chassis-poweroff.target \
    obmc-chassis-poweron.target \
    "
SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " ${@entity_enabled(d, '', '${OLYMPUS_TARGETS}')}"


inherit obmc-phosphor-systemd

FILES_${PN} += "${datadir}/x86-power-control/power-config-host0.json"

do_install_append_olympus-nuvoton() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 -D ${WORKDIR}/power-config-host0.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}
