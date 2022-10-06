FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:buv-runbmc = " \
  file://buv-runbmc.cfg \
  file://0001-i2c-npcm-add-retry-probe-to-fix-sometime-SCL-SDA-low.patch \
  file://0006-driver-SPI-add-w25q01jv-support.patch \
  file://0007-Ampere-Altra-MAX-SSIF-IPMI-driver.patch \
  file://0008-driver-misc-seven-segment-display-gpio-driver.patch \
  "
SRC_URI:append:buv-runbmc = " file://disable_CONFIG_MTD_PARTITIONED_MASTER.cfg" 
SRC_URI:append:buv-runbmc = " file://disable_CONFIG_SYSFS_DEPRECATED.cfg"
SRC_URI:append:buv-runbmc = " file://enable-v4l2.cfg"
