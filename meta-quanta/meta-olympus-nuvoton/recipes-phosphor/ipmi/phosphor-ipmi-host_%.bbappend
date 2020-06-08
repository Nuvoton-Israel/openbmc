SRC_URI_remove_olympus-nuvoton = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_olympus-nuvoton = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "e8cdfd2cf8df3df6a41cae96193988238a9b1100"

FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " olympus-nuvoton-yaml-config"

EXTRA_OECONF_olympus-nuvoton = " \
    --with-journal-sel \
    --enable-boot-flag-safe-mode-support \
    SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml \
    INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-inventory-sensors.yaml \
    FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml \
    "

SRC_URI_append_olympus-nuvoton = " file://phosphor-ipmi-host.service"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_LINK_${PN}_remove_olympus-nuvoton += "${@compose_list_zip(d, 'SOFT_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE_${PN}_remove_olympus-nuvoton += "xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append_olympus-nuvoton() {
    install -d ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
}
