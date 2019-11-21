KBRANCH ?= "dev-5.2"
LINUX_VERSION ?= "5.2.11"

SRCREV="f9e04c3157234671b9d5e27bf9b7025b8b21e0d4"

require linux-nuvoton.inc

SRC_URI += "file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI += "file://0001-add-tps53622-and-tps53659.patch"
SRC_URI += "file://0001-i2c-nuvoton-npcm750-runbmc-integrate-the-slave-mqueu.patch"
SRC_URI += "file://0001-stmmac-Add-eee-fixup-disable.patch"

SRC_URI += "file://0001-reset-npcm-add-NPCM-reset-controller-driver.patch"
SRC_URI += "file://0001-spi-npcm-add-reset-support-to-NPCM-SPI-driver.patch"
SRC_URI += "file://0001-iio-npcm-add-reset-support-to-NPCM-ADC-driver.patch"
SRC_URI += "file://0001-net-nuvoton-add-reset-support-to-NPCM7xx-EMC-driver.patch"
SRC_URI += "file://0001-usb-host-add-reset-support-to-NPCM7xx-ehci-driver.patch"

SRC_URI += "file://0001-dts-nuvoton-add-nuvotn-runbmc-olympus-support.patch"
SRC_URI += "file://0001-dts-nuvoton-npcm7xx-correct-gfxi-offset.patch"
SRC_URI += "file://0001-dts-npcm7xx-add-reset-support-to-NPCM7xx-device-tree.patch"
SRC_URI += "file://0001-dts-npcm7xx-add-reset-support-to-SPI-node.patch"
SRC_URI += "file://0001-dts-npcm7xx-add-reset-support-to-ADC-node.patch"
SRC_URI += "file://0001-dts-npcm7xx-add-reset-support-to-EMC-node.patch"
SRC_URI += "file://0001-dts-npcm7xx-correct-vcd-and-ece-node.patch"
SRC_URI += "file://0001-dts-npcm7xx-runbmc-config-jtag-master-pins.patch"

SRC_URI += "file://0001-driver-i2c-nuvoton-v26-test.patch"
SRC_URI += "file://0001-driver-usb-udc-add-NPCM-UDC.patch"
SRC_URI += "file://0001-driver-media-nuvoton-vcd-and-ece-driver.patch"
SRC_URI += "file://0001-driver-net-emc-driver-update.patch"
SRC_URI += "file://0001-driver-mtd-npcm-update-driver.patch"
SRC_URI += "file://0001-driver-hwrng-add-NPCM-RNG.patch"
SRC_URI += "file://0001-driver-misc-add-jtag-master-driver-for-npcm7xx.patch"

SRC_URI += "file://0001-driver-ncsi-replace-del-timer-sync.patch"
