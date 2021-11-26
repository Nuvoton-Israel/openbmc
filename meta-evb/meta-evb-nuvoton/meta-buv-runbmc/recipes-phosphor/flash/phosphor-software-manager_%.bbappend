FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " \
    file://support_update_uboot_with_emmc_image.patch \
    file://restore_verify_bios.patch \
    file://report_same_version.patch \
    "

PACKAGECONFIG:buv-runbmc += "verify_signature flash_bios"
EXTRA_OEMESON:append:buv-runbmc = " -Doptional-images=image-bios"
