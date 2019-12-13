SRC_URI_remove_olympus-nuvoton = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_olympus-nuvoton = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "e7ff33f39ff00e71396b0359dbfca6950cb0204d"

FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " olympus-nuvoton-yaml-config"

EXTRA_OECONF_olympus-nuvoton = " \
    --with-journal-sel \
    SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml \
    INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-inventory-sensors.yaml \
    FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml \
    "

SRC_URI_append_olympus-nuvoton = " file://phosphor-ipmi-host.service"
SRC_URI_append_olympus-nuvoton = " file://xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"
SRC_URI_append_olympus-nuvoton = " file://0001-Add-support-for-enabling-disabling-network-IPMI.patch"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-ipmi-host.service"
SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append_olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service \
        ${D}${systemd_unitdir}/system
}
