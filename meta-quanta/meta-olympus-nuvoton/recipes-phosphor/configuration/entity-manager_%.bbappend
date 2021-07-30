FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"
inherit obmc-phosphor-systemd

SRC_URI_append_olympus-nuvoton = " file://F0B_BMC_MB.json"
SRC_URI_append_olympus-nuvoton = " file://xyz.openbmc_project.EntityManager.service"
SRC_URI_append_olympus-nuvoton = " file://xyz.openbmc_project.FruDevice.service"

FILES_${PN} += "${datadir}/entity-manager/F0B_BMC_MB.json"

# reload sensor service files
SRC_URI_append_olympus-nuvoton = " \
    file://olympus-reload-sensor-on.service \
    file://olympus-reload-sensor-off.service \
    file://olympus-reload-sensor.sh"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " \
    olympus-reload-sensor-on.service \
    olympus-reload-sensor-off.service"

SENSOR_ON_TMPL = "olympus-reload-sensor-on.service"
CHASSIS_POWERON_TGTFMT = "obmc-chassis-poweron.target"
ENABLE_POWER_FMT = "../${SENSOR_ON_TMPL}:${CHASSIS_POWERON_TGTFMT}.wants/${SENSOR_ON_TMPL}"
SYSTEMD_LINK_${PN} += "${@compose_list(d, 'ENABLE_POWER_FMT', 'OBMC_CHASSIS_INSTANCES')}"

SENSOR_OFF_TMPL = "olympus-reload-sensor-off.service"
CHASSIS_POWEROFF_TGTFMT = "obmc-chassis-poweroff.target"
DISABLE_POWER_FMT = "../${SENSOR_OFF_TMPL}:${CHASSIS_POWEROFF_TGTFMT}.wants/${SENSOR_OFF_TMPL}"
SYSTEMD_LINK_${PN} += "${@compose_list(d, 'DISABLE_POWER_FMT', 'OBMC_CHASSIS_INSTANCES')}"

do_install_append_olympus-nuvoton() {
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${WORKDIR}/F0B_BMC_MB.json \
        ${D}${datadir}/entity-manager/configurations/F0B_BMC_MB.json
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/olympus-reload-sensor.sh ${D}${bindir}
}
