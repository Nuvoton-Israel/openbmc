FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/linux-nuvoton:"
inherit entity-utils

SRC_URI:append:buv-runbmc = " \
  file://buv-runbmc.cfg \
  file://0001-i2c-npcm-add-retry-probe-to-fix-sometime-SCL-SDA-low.patch \
  file://0006-driver-SPI-add-w25q01jv-support.patch \
  file://0008-driver-misc-seven-segment-display-gpio-driver.patch \
  file://0009-Add-buv-runbmc-PSU-driver-inspur-ipsps.c.patch \
  file://0010-dts-add-two-test-PSUs-settings.patch \
  file://0012-Don-t-use-Write_PROTECT-command-in-chicony-psu.patch \
  "

SRC_URI:append:buv-runbmc = " \
  ${@bb.utils.contains('DISTRO_FEATURES', 'kdump', 'file://kdump.cfg', '', d)}"
