inherit entity-utils

FILESEXTRAPATHS_append_evb-npcm845 := "${THISDIR}/${PN}:"

DEPENDS_append_evb-npcm845 = " ${@entity_enabled(d, '', ' evb-npcm845-yaml-config')}"
EXTRA_OECONF_append_evb-npcm845 = " ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-sensors.yaml')}"
EXTRA_OECONF_append_evb-npcm845 = " ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-fru-read.yaml')}"
EXTRA_OECONF_append_evb-npcm845 = " ${@entity_enabled(d, '', 'INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-inventory-sensors.yaml')}"
EXTRA_OECONF_append_evb-npcm845 = " --disable-i2c-whitelist-check"

# Fixed ipmid crashing in 64bit system, an alternative solution is still in upstream reviewing
# https://gerrit.openbmc-project.xyz/c/openbmc/phosphor-host-ipmid/+/44260
SRC_URI_append_evb-npcm845 = " file://0001-phosphor-ipmi-host-Do-not-use-size_t-in-struct-MetaP.patch"

# Add send/get message support
# ipmid <-> ipmb <-> i2c
SRC_URI_append_evb-npcm845 = " file://0002-Support-bridging-commands.patch"

# Get sel events from journal logs, the build opetion should with "--with-journal-sel"
# EXTRA_OECONF_append_evb-npcm845 = " --with-journal-sel"
SRC_URI_append_evb-npcm845 = " file://0004-Add-option-for-SEL-commands-for-Journal-based-SEL-en.patch"

PACKAGECONFIG_append_evb-npcm845 = " ${@entity_enabled(d, 'dynamic-sensors', '')}"
SRC_URI_append_evb-npcm845 = " file://0005-dbus-sdr-prevent-handler-registration-if-dbus-sdr-is.patch"

# avoid build error after remove ipmi-fru
WHITELIST_CONF_evb-npcm845 = "${S}/host-ipmid-whitelist.conf"
