FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/u-boot-nuvoton:"

SRC_URI:append:evb-npcm845 = " file://emmc.cfg"
#SRC_URI:append:evb-npcm845 = " file://ncsi.cfg"
SRC_URI:append:evb-npcm845 = " file://ftpm.cfg"
SRC_URI:append:evb-npcm845 = " file://mem_hide.cfg"
