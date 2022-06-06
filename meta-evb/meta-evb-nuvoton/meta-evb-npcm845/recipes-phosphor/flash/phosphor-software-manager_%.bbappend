FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

#SRC_URI:append:evb-npcm845 = " file://support_update_uboot_with_emmc_image.patch"
SRC_URI:append:evb-npcm845 = " file://restore_verify_bios.patch"
#SRC_URI:append:evb-npcm845 = " file://report_same_version.patch"

PACKAGECONFIG:evb-npcm845 += "verify_signature flash_bios"
EXTRA_OEMESON:append:evb-npcm845 = " -Doptional-images=image-bios"
