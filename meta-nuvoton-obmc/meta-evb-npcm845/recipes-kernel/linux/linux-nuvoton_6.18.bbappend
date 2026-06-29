FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton-618:${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://evb-npcm845-stage.cfg"
SRC_URI:append = " file://luks.cfg"

# enable v4l2 VCD/ECE driver
SRC_URI:append = " file://enable-v4l2-kvm.cfg"

# enable hdmi to usb video class, media support, video devic
# User must disale enable-v4l2-kvm.cfg to prvent conflict with obmc kvm application
#SRC_URI:append = " file://enable-usb-video.cfg"

# enable legavcy kvm driver, mutex vl42 driver 
#SRC_URI:append = " file://enable-legacy-kvm.cfg"
#SRC_URI:append = " file://0001-driver-misc-enable-the-FIFO-overrun-underrun-interru.patch"

# support OpenBMC flash partition
SRC_URI:append = " file://0002-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
SRC_URI:append = " file://0003-dts-update-flash-layout-for-TIP-2M.patch"

# enable slave eeprom for gfx edid
SRC_URI:append = " file://0004-dts-npcm845-evb-enable-slave-eeprom-on-i2c11.patch"

# enable i3c0 GDMA
SRC_URI:append = " file://0005-dts-arm64-evb-npcm845-enable-gdma-on-i3c0.patch"

# Enable af_mctp on i3c and i2c
SRC_URI:append = " file://0006-dts-mctp-i2c-controller.patch"
SRC_URI:append = " file://0007-dts-mctp-i3c-controller.patch"
SRC_URI:append = " file://af_mctp.cfg"

# Enable ttyS1, ttyS2, ttyS3, ttyS4, ttyS5
SRC_URI:append = " file://0009-arm64-dts-npcm845-evb-enable-more-serial-interfaces.patch"

# Set high slew rate for PSPI pins
SRC_URI:append = " file://0011-dts-arm64-npcm845-evb-Set-high-slew-rate-for-PSPI-pi.patch"

# add jtm spi driver
SRC_URI:append = " file://0012-add-jtm-spi-driver.patch"
#SRC_URI:append = " file://spi_jtm.cfg"

# Enable mmbi interface
#SRC_URI:append = " file://0013-dts-arm64-npcm845-evb-enable-mmbi.patch"

# Enable voltage divider for ADC
SRC_URI:append = " file://0014-dts-arm64-evb-npcm845-use-voltage-divider.patch"
SRC_URI:append = " file://iio_rescale.cfg"

