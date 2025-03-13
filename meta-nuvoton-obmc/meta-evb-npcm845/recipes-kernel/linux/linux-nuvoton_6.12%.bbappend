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

# CPLD UART
# SRC_URI:append = " file://1000-support-CPLD-UART-16450.patch"

# kernel boot from fiu0 cs1
# SRC_URI:append = " file://1010-dts-nuvoton-evb-npcm845-boot-from-fiu0-cs1.patch"

# for i3c slave test
# SRC_URI:append = " file://1020-dts-i3c-slave.patch"
# SRC_URI:append = " file://intel_i3c_mctp.cfg"

# support af_mctp over pcie vdm
# SRC_URI:append = " file://1030-kernel-dts-support-for-MCTP-verification.patch"
# SRC_URI:append = " file://af_mctp_vdm.cfg"

# for i3c hub
# SRC_URI:append = " file://i3c_hub.cfg"
# SRC_URI:append = " file://1040-dts-add-i3c-hub-node-to-support-two-bic-slave-device.patch"

# for npcm bic
# SRC_URI:append = " file://1050-i3c-master-svc-add-delay-for-NPCM-BIC.patch"
