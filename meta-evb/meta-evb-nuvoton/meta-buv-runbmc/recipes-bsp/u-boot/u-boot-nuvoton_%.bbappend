FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/u-boot-nuvoton:"

UBOOT_MAKE_TARGET:append:buv-runbmc = " DEVICE_TREE=${UBOOT_DEVICETREE}"

SRC_URI:append:buv-runbmc = " file://fixed_phy.cfg"
SRC_URI:append:buv-runbmc = " file://fit_sig.cfg"
SRC_URI:append:buv-runbmc = " file://0001-arch-arm-npcm-Set-fuse-images-after-uboot-end.patch"
