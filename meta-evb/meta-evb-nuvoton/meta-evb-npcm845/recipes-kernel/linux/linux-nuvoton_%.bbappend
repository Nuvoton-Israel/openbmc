FILESEXTRAPATHS_prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI_append_evb-npcm845 = " file://evb-npcm845.cfg"
SRC_URI_append_evb-npcm845 = " file://0001-kernel-dts-npcm845-dts-update.patch"
