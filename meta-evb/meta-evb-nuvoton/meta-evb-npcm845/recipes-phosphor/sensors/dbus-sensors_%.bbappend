FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

PACKAGECONFIG:evb-npcm845 = "\
    hwmontempsensor \
    fansensor \
    adcsensor \
    "
