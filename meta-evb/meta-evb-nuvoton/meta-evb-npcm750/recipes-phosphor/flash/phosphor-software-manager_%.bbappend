FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

PACKAGECONFIG:append:evb-npcm750 = " verify_signature flash_bios"

SRC_URI:append:evb-npcm750 = " file://restore_verify_bios.patch"
#SRC_URI:append:evb-npcm750 = " file://support_update_uboot_with_emmc_image.patch"

EXTRA_OEMESON:append:evb-npcm750 = " -Doptional-images=image-bios"
