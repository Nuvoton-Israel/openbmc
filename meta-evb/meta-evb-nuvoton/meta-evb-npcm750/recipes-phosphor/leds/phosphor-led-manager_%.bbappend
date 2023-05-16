FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://LED_GroupManager.conf"

SYSTEMD_OVERRIDE:${PN}:evb-npcm750 += "LED_GroupManager.conf:xyz.openbmc_project.LED.GroupManager.service.d/LED_GroupManager.conf"
