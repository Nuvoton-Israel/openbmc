FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " \
    file://0001-hwmon-temp-add-lm75-support.patch \
    "

PACKAGECONFIG:evb-npcm750 = "\
    hwmontempsensor \
    fansensor \
    adcsensor \
    "
