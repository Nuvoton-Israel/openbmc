FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm845 = " file://LED_GroupManager.conf"

SYSTEMD_OVERRIDE:${PN}-ledmanager += "LED_GroupManager.conf:xyz.openbmc_project.LED.GroupManager.service.d/LED_GroupManager.conf"
