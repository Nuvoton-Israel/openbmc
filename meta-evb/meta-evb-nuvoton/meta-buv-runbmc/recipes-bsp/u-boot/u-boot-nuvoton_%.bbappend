FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/u-boot-nuvoton:"

UBOOT_MAKE_TARGET_append_buv-runbmc = " DEVICE_TREE=${UBOOT_DEVICETREE}"

SRC_URI_append_buv-runbmc = " file://fixed_phy.cfg"
