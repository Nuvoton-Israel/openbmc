inherit entity-utils
SRC_URI_remove_olympus-nuvoton = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_olympus-nuvoton = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "3f553e155500938a51a06173633c51be87ec463a"

FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " \
    ${@entity_enabled(d, '', 'olympus-nuvoton-yaml-config')}"

EXTRA_OECONF_olympus-nuvoton = " \
    --with-journal-sel \
    --enable-boot-flag-safe-mode-support \
    ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml')} \
    ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml')} \
    "
PACKAGECONFIG_append_olympus-entity = " dynamic-sensors"

SRC_URI_append_olympus-nuvoton = " file://phosphor-ipmi-host.service"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_LINK_${PN}_remove_olympus-nuvoton += "${@compose_list_zip(d, 'SOFT_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE_${PN}_remove_olympus-nuvoton += "xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append_olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
}

do_install_append_olympus-entity(){
    install -d ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
}
