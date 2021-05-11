SRC_URI_remove_olympus-nuvoton = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_olympus-nuvoton = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "df9d9530ae063708cd39b38b6b7d896c14087ed5"

FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " olympus-nuvoton-yaml-config"

EXTRA_OECONF_olympus-nuvoton = " \
    --with-journal-sel \
    --enable-boot-flag-safe-mode-support \
    SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml \
    FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml \
    --disable-dynamic_sensors \
    "

SRC_URI_append_olympus-nuvoton = " file://phosphor-ipmi-host.service"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_LINK_${PN}_remove_olympus-nuvoton += "${@compose_list_zip(d, 'SOFT_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE_${PN}_remove_olympus-nuvoton += "xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append_olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
}
