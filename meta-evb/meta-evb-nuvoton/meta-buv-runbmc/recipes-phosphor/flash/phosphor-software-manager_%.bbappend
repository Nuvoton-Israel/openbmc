FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " \
    file://0001-Restore-and-verify-BIOS.patch \
    file://0002-Support-ignore-update-uboot-with-eMMC-image.patch \
    "

PACKAGECONFIG:append:buv-runbmc = " verify_signature flash_bios"
EXTRA_OEMESON:append:buv-runbmc = " -Doptional-images=image-bios"
