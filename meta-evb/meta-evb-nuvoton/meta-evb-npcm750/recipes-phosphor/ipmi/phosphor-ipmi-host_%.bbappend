inherit entity-utils

FILESEXTRAPATHS:append:evb-npcm750 := "${THISDIR}/${PN}:"

DEPENDS:append:evb-npcm750 = " ${@entity_enabled(d, '', ' evb-npcm750-yaml-config')}"

EXTRA_OEMESON:append:evb-npcm750 = " \
    ${@entity_enabled(d, '', '-Dsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/evb-npcm750-yaml-config/ipmi-sensors.yaml')} \
    ${@entity_enabled(d, '', '-Dfru-yaml-gen=${STAGING_DIR_HOST}${datadir}/evb-npcm750-yaml-config/ipmi-fru-read.yaml')} \
    ${@entity_enabled(d, '', '-Dinvsensor-yaml-gen=${STAGING_DIR_HOST}${datadir}/evb-npcm750-yaml-config/ipmi-inventory-sensors.yaml')} \
    "

EXTRA_OEMESON:append:evb-npcm750 = " -Di2c-whitelist-check=disabled"
EXTRA_OEMESON:append:evb-npcm750 = " -Dsel-logger-clears-sel=enabled"


# Add send/get message support
# ipmid <-> ipmb <-> i2c
SRC_URI:append:evb-npcm750 = " file://0002-Support-bridging-commands.patch"

PACKAGECONFIG:append:evb-npcm750 = " ${@entity_enabled(d, 'dynamic-sensors', '')}"

# avoid build error after remove ipmi-fru
WHITELIST_CONF:evb-npcm750 = "${S}/host-ipmid-whitelist.conf"
