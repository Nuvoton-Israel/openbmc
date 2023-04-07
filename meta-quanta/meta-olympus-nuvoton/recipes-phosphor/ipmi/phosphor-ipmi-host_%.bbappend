inherit entity-utils

FILESEXTRAPATHS:append:olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append:olympus-nuvoton = " \
    file://0001-Add-set-BIOS-version-support.patch \
    file://0002-Add-support-for-enabling-disabling-network-IPMI.patch \
    "

DEPENDS:append:olympus-nuvoton = " \
    ${@entity_enabled(d, '', 'olympus-nuvoton-yaml-config')}"

EXTRA_OEMESON:append:olympus-nuvoton = " \
    -Dboot-flag-safe-mode-support=enabled \
    ${@entity_enabled(d, '', '-Dsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-sensors.yaml')} \
    ${@entity_enabled(d, '', '-Dfru-yaml-gen=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-fru-read.yaml')} \
    ${@entity_enabled(d, '', '-Dinvsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/olympus-nuvoton-yaml-config/ipmi-inventory-sensors.yaml')} \
    "
PACKAGECONFIG:append:olympus-entity = " dynamic-sensors"

EXTRA_OEMESON:append:buv-runbmc = " -Di2c-whitelist-check=disabled"

# for intel ipmi oem
do_install:append:olympus-nuvoton(){
    install -d ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/sensorhandler.hpp ${D}${includedir}/phosphor-ipmi-host
    install -m 0644 -D ${S}/selutility.hpp ${D}${includedir}/phosphor-ipmi-host
}
