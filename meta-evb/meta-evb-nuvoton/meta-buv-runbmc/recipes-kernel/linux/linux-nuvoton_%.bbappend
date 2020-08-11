FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/linux-nuvoton:"

SRC_URI_append_buv-runbmc = " file://buv-runbmc.cfg"
SRC_URI_append_buv-runbmc = " \
  file://0001-dts-nuvoton-add-buv-runbmc-support.patch \
  file://0002-move-emc-debug-message-to-dev_dbg.patch \
  file://0003-add-seven_seg_gpio.patch \
  file://0004-misc-Character-device-driver.patch \
  "
