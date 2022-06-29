inherit entity-utils

FILESEXTRAPATHS:append:evb-npcm845 := "${THISDIR}/${PN}:"

DEPENDS:append:evb-npcm845 = " ${@entity_enabled(d, '', ' evb-npcm845-yaml-config')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-sensors.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-fru-read.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-inventory-sensors.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " --disable-i2c-whitelist-check"

SRC_URI:append:evb-npcm845 = " file://0001-Add-Set-BIOS-version-support.patch"

# Fixed ipmid crashing in 64bit system, an alternative solution is still in upstream reviewing
# https://gerrit.openbmc-project.xyz/c/openbmc/phosphor-host-ipmid/+/44260
SRC_URI:append:evb-npcm845 = " file://0001-phosphor-ipmi-host-Do-not-use-size_t-in-struct-MetaP.patch"

# Add send/get message support
# ipmid <-> ipmb <-> i2c
SRC_URI:append:evb-npcm845 = " file://0002-Support-bridging-commands.patch"

# Get sel events from journal logs, the build opetion should with "--with-journal-sel"
# EXTRA_OECONF:append:evb-npcm845 = " --with-journal-sel"
# SRC_URI:append:evb-npcm845 = " file://0004-Add-option-for-SEL-commands-for-Journal-based-SEL-en.patch"

PACKAGECONFIG:append:evb-npcm845 = " ${@entity_enabled(d, 'dynamic-sensors', '')}"

# avoid build error after remove ipmi-fru
WHITELIST_CONF:evb-npcm845 = "${S}/host-ipmid-whitelist.conf"

SRC_URI:append:evb-npcm845 = " file://0006-Correct-IPMI-firmware-revision-report.patch"

SRC_URI:append:evb-npcm845 = " file://0007-dbus-sdr-storagecommands-Add-option-to-use-Clear-met.patch"
EXTRA_OECONF:append:evb-npcm845 = " --enable-sel_logger_clears_sel"

SRC_URI:append:evb-npcm845 = " file://0001-dbus-sdr-Support-NaN-thresholds.patch"
