FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/u-boot-nuvoton:"
SRC_URI:append:evb-npcm845 = " file://0002-Enable-openbmc-copy-base-file-to-ram-feature.patch"
