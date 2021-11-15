FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:buv-runbmc = " \
  file://arch \
  file://buv-runbmc.cfg \
  file://0001-i2c-npcm-add-retry-probe-to-fix-sometime-SCL-SDA-low.patch \
  file://0006-driver-SPI-add-w25q01jv-support.patch \
  file://0007-Ampere-Altra-MAX-SSIF-IPMI-driver.patch \
  file://0008-driver-misc-seven-segment-display-gpio-driver.patch \
  "

# Merge source tree by original project with our layer of additional files
do_add_vesnin_files () {
    cp -r "${WORKDIR}/arch" \
          "${STAGING_KERNEL_DIR}"
}
addtask do_add_vesnin_files after do_kernel_checkout before do_patch
