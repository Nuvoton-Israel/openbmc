FILESEXTRAPATHS:append:evb-npcm845 := "${THISDIR}/${PN}:"

DEPENDS:append:evb-npcm845 = " evb-npcm845-yaml-config"
EXTRA_OECONF:append:evb-npcm845 = " SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-sensors.yaml"
EXTRA_OECONF:append:evb-npcm845 = " FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-fru-read.yaml"
EXTRA_OECONF:append:evb-npcm845 = " INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm845-yaml-config/ipmi-inventory-sensors.yaml"

# Fixed ipmid crashing in 64bit system, an alternative solution is still in upstream reviewing
# https://gerrit.openbmc-project.xyz/c/openbmc/phosphor-host-ipmid/+/44260
SRC_URI:append:evb-npcm845 = " file://0001-phosphor-ipmi-host-Do-not-use-size_t-in-struct-MetaP.patch"

# Add send/get message support
# ipmid <-> ipmb <-> i2c
SRC_URI:append:evb-npcm845 = " file://0002-Support-bridging-commands.patch"

# Add oem command to get bios post code
#SRC_URI:append:evb-npcm845 = " file://0003-add-oem-command-get-bios-post-code.patch"

# Get sel events from journal logs, the build opetion should with "--with-journal-sel"
# EXTRA_OECONF:append:evb-npcm845 = " --with-journal-sel"
# SRC_URI:append:evb-npcm845 = " file://0004-Add-option-for-SEL-commands-for-Journal-based-SEL-en.patch"
