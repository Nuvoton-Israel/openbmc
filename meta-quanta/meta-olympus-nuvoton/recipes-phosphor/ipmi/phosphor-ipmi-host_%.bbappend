inherit entity-utils

FILESEXTRAPATHS:append:olympus-nuvoton := "${THISDIR}/${PN}:"
SRC_URI:append:olympus-nuvoton = " \
    file://0059-Move-Set-SOL-config-parameter-to-host-ipmid.patch \
    file://0060-Move-Get-SOL-config-parameter-to-host-ipmid.patch \
    file://Add-Set-BIOS-version-support.patch \
    "

DEPENDS:append:olympus-nuvoton = " \
    ${@entity_enabled(d, '', 'olympus-nuvoton-yaml-config')}"

EXTRA_OECONF:olympus-nuvoton = " \
    --enable-boot-flag-safe-mode-support \
    ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml')} \
    ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml')} \
    "
PACKAGECONFIG:append:olympus-entity = " dynamic-sensors"

SRC_URI:append:olympus-nuvoton = " file://phosphor-ipmi-host.service"
#SRC_URI:append:olympus-nuvoton = " file://0001-add-watchdog-sensor-type.patch"

SYSTEMD_SERVICE:${PN}:append:olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_LINK:${PN}:remove:olympus-nuvoton += "${@compose_list_zip(d, 'SOFT_FMT', 'OBMC_HOST_INSTANCES')}"
SYSTEMD_SERVICE:${PN}:remove:olympus-nuvoton += "xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install:append:olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
}

do_install:append:olympus-entity(){
    install -d ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
}
