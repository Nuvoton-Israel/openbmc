FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/u-boot-nuvoton:"

SRC_URI:append:evb-npcm845 = " file://emmc.cfg"
#SRC_URI:append:evb-npcm845 = " file://ncsi.cfg"
SRC_URI:append:evb-npcm845 = " file://ftpm.cfg"
SRC_URI:append:evb-npcm845 = " file://mem_hide.cfg"
SRC_URI:append:evb-npcm845 = " file://fit_sig.cfg"
#SRC_URI:append:evb-npcm845 = " file://disable_sha_hw.cfg"
SRC_URI:append:evb-npcm845 = " file://wdt.cfg"

#SRC_URI:append:evb-npcm845 = " file://0001-board-nuvoton-arbel-add-spix-init.patch"
SRC_URI:append:evb-npcm845 = " file://0002-Enable-openbmc-copy-base-file-to-ram-feature.patch"
