SRC_URI_remove_evb-npcm750 = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend_evb-npcm750 = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"
SRCREV_evb-npcm750 = "3f553e155500938a51a06173633c51be87ec463a"

DEPENDS_append_evb-npcm750= "evb-npcm750-yaml-config"

EXTRA_OECONF_evb-npcm750 = " \
    --with-journal-sel \
    SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm750-yaml-config/ipmi-sensors.yaml \
    FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/evb-npcm750-yaml-config/ipmi-fru-read.yaml \
    --disable-dynamic_sensors \
    "

