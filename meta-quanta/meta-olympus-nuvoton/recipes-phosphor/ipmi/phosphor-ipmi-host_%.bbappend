SRC_URI_remove_olympus-nuvoton = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_olympus-nuvoton = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "ffbc070b738c196b754720ae27cc277d47610bee"

FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " olympus-nuvoton-yaml-config"

EXTRA_OECONF_olympus-nuvoton = " \
    SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml \
    INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-inventory-sensors.yaml \
    FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml \
    "

SRC_URI_append_olympus-nuvoton = " file://phosphor-ipmi-host.service"
SRC_URI_append_olympus-nuvoton = " file://xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"
SRC_URI_append_olympus-nuvoton = " file://0001-fix-get-property-failed-when-executing-channel-acces.patch"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append_olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service \
        ${D}${systemd_unitdir}/system
}
