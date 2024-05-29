FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/u-boot-nuvoton:"
SRC_URI:append:evb-npcm845 = " file://0001-Update-env-offset-for-layout-change.patch"
SRC_URI:append:evb-npcm845 = " file://0002-Enable-openbmc-copy-base-file-to-ram-feature.patch"
