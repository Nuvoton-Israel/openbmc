FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-nuvoton:"

SRC_URI:append = " file://emmc.cfg"
SRC_URI:append = " file://ftpm.cfg"
SRC_URI:append = " file://mem_hide.cfg"
SRC_URI:append = " file://fit_sig.cfg"
SRC_URI:append = " file://wdt.cfg"
SRC_URI:append = " file://evb-npcm845.cfg"

# SRC_URI:append = " file://ncsi.cfg"
# SRC_URI:append = " file://disable_sha_hw.cfg"

SRC_URI:append = " file://0001-uart2-clock-source-to-24Mhz.patch"
SRC_URI:append = " file://0002-Enable-openbmc-copy-base-file-to-ram-feature.patch"
# SRC_URI:append = " file://0012-Enable-DVO-HSYNC-DDC-i2c-port.patch"

# FPGA test
SRC_URI:append = " file://0001-uboot-enable-espim.patch"
SRC_URI:append = " file://0001-change-espi-master-to-gpio0-26-31-pin-and-disable-i2.patch"
SRC_URI:append = " file://0001-cmd-espi-support-dual-quad-eSPI_ALERT-feature.patch"
SRC_URI:append = " file://0001-cmd-espi-support-getpc-command.patch"
