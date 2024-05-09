FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://evb-npcm845.cfg"
SRC_URI:append = " file://enable-v4l2.cfg"
#SRC_URI:append = " file://enable-legacy-kvm.cfg"
SRC_URI:append = " file://luks.cfg"

SRC_URI:append = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
# SRC_URI:append = " file://0016-support-CPLD-UART-16450.patch"
# SRC_URI:append = " file://0002-dts-nuvoton-evb-npcm845-boot-from-fiu0-cs1.patch"
SRC_URI:append:evb-npcm845 = " file://0005-dts-update-flash-layout-for-TIP-2M.patch"

# For gfx edid
SRC_URI:append = " file://0001-dts-npcm845-evb-enable-slave-eeprom-on-i2c11.patch"

# for i3c slave test
# SRC_URI:append = " file://0001-dts-i3c-slave.patch"
# SRC_URI:append = " file://i3c_mctp.cfg"

# for af_mctp test
SRC_URI:append = " file://0001-dts-mctp-i2c-controller.patch"
SRC_URI:append = " file://0002-dts-mctp-i3c-controller.patch"
SRC_URI:append = " file://0004-dts-evb-npcm845-enable-udc8.patch"
SRC_URI:append = " file://mctp.cfg"

# Support af_mctp over pcie vdm
# SRC_URI:append = " file://mctp_vdm.cfg"
# SRC_URI:append = " file://0001-kernel-dts-support-for-MCTP-verification.patch"

# for i3c hub
SRC_URI:append = " file://i3c_hub.cfg"
SRC_URI:append = " file://0001-dts-add-i3c-hub-node-to-support-two-bic-slave-device.patch"

# for npcm bic
# SRC_URI:append = " file://0001-i3c-master-svc-add-delay-for-NPCM-BIC.patch"
