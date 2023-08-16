FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton-515:${THISDIR}/linux-nuvoton:"

SRC_URI:append:evb-npcm845 = " file://evb-npcm845.cfg"
SRC_URI:append:evb-npcm845 = " file://enable-v4l2.cfg"
SRC_URI:append:evb-npcm845 = " file://luks.cfg"

SRC_URI:append:evb-npcm845 = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
