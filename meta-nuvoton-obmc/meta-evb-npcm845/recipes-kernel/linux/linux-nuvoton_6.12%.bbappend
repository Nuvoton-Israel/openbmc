FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://evb-npcm845-stage.cfg"
SRC_URI:append = " file://enable-v4l2.cfg"
SRC_URI:append = " file://luks.cfg"

# enable legavcy kvm driver, mutex vl42 driver 
# SRC_URI:append = " file://enable-legacy-kvm.cfg"

# support OpenBMC flash partition
SRC_URI:append = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
SRC_URI:append = " file://0002-dts-update-flash-layout-for-TIP-2M.patch"

# enable slave eeprom for gfx edid
SRC_URI:append = " file://0003-dts-npcm845-evb-enable-slave-eeprom-on-i2c11.patch"

# enable i3c0 GDMA
SRC_URI:append = " file://0004-dts-arm64-evb-npcm845-enable-gdma-on-i3c0.patch"

# Enable af_mctp on i3c and i2c
SRC_URI:append = " file://0005-dts-mctp-i2c-controller.patch"
SRC_URI:append = " file://0006-dts-mctp-i3c-controller.patch"
SRC_URI:append = " file://af_mctp.cfg"

# Enable UDC8 on usb phy3
SRC_URI:append = " file://0007-dts-evb-npcm845-enable-udc8.patch"
