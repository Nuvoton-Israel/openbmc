inherit entity-utils

FILESEXTRAPATHS:append:evb-npcm845 := "${THISDIR}/${PN}:"

DEPENDS:append:evb-npcm845 = " ${@entity_enabled(d, '', ' evb-npcm845-yaml-config')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-sensors.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-fru-read.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " ${@entity_enabled(d, '', 'INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-inventory-sensors.yaml')}"
EXTRA_OECONF:append:evb-npcm845 = " --disable-i2c-whitelist-check"

SRC_URI:append:evb-npcm845 = " file://0001-Add-Set-BIOS-version-support.patch"
SRC_URI:append:evb-npcm845 = " file://0001-dbus-sdr-Support-NaN-thresholds.patch"
SRC_URI:append:evb-npcm845 = " file://0004-Add-SEL-add-command.patch"
SRC_URI:append:evb-npcm845 = " file://0006-Correct-IPMI-firmware-revision-report.patch"
SRC_URI:append:evb-npcm845 = " file://0007-dbus-sdr-storagecommands-Add-option-to-use-Clear-met.patch"
SRC_URI:append:evb-npcm845 = " file://0008-Add-sensor-type-command.patch"
SRC_URI:append:evb-npcm845 = " file://0011-Add-SEL-time-set-command.patch"
SRC_URI:append:evb-npcm845 = " file://0012-Force-self-test-OK.patch"

# Add send/get message support
# ipmid <-> ipmb <-> i2c
SRC_URI:append:evb-npcm845 = " file://0002-Support-bridging-commands.patch"

PACKAGECONFIG:append:evb-npcm845 = " ${@entity_enabled(d, 'dynamic-sensors', '')}"

# avoid build error after remove ipmi-fru
WHITELIST_CONF:evb-npcm845 = "${S}/host-ipmid-whitelist.conf"

EXTRA_OECONF:append:evb-npcm845 = " --enable-sel_logger_clears_sel"

