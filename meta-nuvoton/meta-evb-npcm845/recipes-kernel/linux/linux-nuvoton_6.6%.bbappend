FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:evb-npcm845 = " file://evb-npcm845.cfg"
SRC_URI:append:evb-npcm845 = " file://enable-v4l2.cfg"
#SRC_URI:append:evb-npcm845 = " file://enable-legacy-kvm.cfg"
SRC_URI:append:evb-npcm845 = " file://luks.cfg"

SRC_URI:append:evb-npcm845 = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
# SRC_URI:append:evb-npcm845 = " file://0016-support-CPLD-UART-16450.patch"
# SRC_URI:append:evb-npcm845 = " file://0002-dts-nuvoton-evb-npcm845-boot-from-fiu0-cs1.patch"
SRC_URI:append:evb-npcm845 = " file://0005-dts-update-flash-layout-for-TIP-2M.patch"

# For gfx edid
SRC_URI:append:evb-npcm845 = " file://0001-dts-npcm845-evb-enable-slave-eeprom-on-i2c11.patch"

# for i3c slave test
# SRC_URI:append:evb-npcm845 = " file://0001-dts-i3c-slave.patch"
# SRC_URI:append:evb-npcm845 = " file://i3c_mctp.cfg"

# for af_mctp test
# SRC_URI:append:evb-npcm845 = " file://0001-dts-mctp-i2c-controller.patch"
# SRC_URI:append:evb-npcm845 = " file://0002-dts-mctp-i3c-controller.patch"
# SRC_URI:append:evb-npcm845 = " file://0004-dts-evb-npcm845-enable-udc8.patch"
SRC_URI:append:evb-npcm845 = " file://mctp.cfg"


SRC_URI:append:evb-npcm845 = " file://0001-dts-arm64-npcm845-evb-enable-all-uarts.patch"
SRC_URI:append:evb-npcm845 = " file://0001-dts-arm64-npcm845-evb-disable-fiu-drd-and-decrease-i.patch"
SRC_URI:append:evb-npcm845 = " file://0001-dts-define-7seg-gpio-names.patch"
# Support af_mctp over pcie vdm
# SRC_URI:append:evb-npcm845 = " file://mctp_vdm.cfg"
# SRC_URI:append:evb-npcm845 = " file://0001-kernel-dts-support-for-MCTP-verification.patch"

# for i3c hub
#SRC_URI:append:evb-npcm845 = " file://i3c_hub.cfg"
#SRC_URI:append:evb-npcm845 = " file://0001-dts-add-i3c-hub-node-to-support-two-bic-slave-device.patch"

# for npcm bic
# SRC_URI:append:evb-npcm845 = " file://0001-i3c-master-svc-add-delay-for-NPCM-BIC.patch"

SRC_URI:append:evb-npcm845 = " file://0001-usb-Add-generic-MCTP-include.patch"
SRC_URI:append:evb-npcm845 = " file://0002-net-mctp-Add-MCTP-USB-transport-driver.patch"
SRC_URI:append:evb-npcm845 = " file://0003-usb-gadget-Add-MCTP-USB-function.patch"
SRC_URI:append:evb-npcm845 = " file://0004-usb-gadget-mctp-defer-tx-to-batch.patch"
SRC_URI:append:evb-npcm845 = " file://0005-driver-usb-f_mctp-add-high-speed-support.patch"
SRC_URI:append:evb-npcm845 = " file://0006-driver-mctp-usb-fix-rx-issue.patch"
SRC_URI:append:evb-npcm845 = " file://0007-driver-mctp-usb-set-max-mtu-to-255.patch"
SRC_URI:append:evb-npcm845 = " file://0008-usb-gadget-f_mctp-fix-kernel-panic.patch"
SRC_URI:append:evb-npcm845 = " file://0001-driver-soc-nuvoton-add-espi-slave-driver.patch"
SRC_URI:append:evb-npcm845 = " file://0009-driver-mctp-usb-correct-statistics.patch"
SRC_URI:append:evb-npcm845 = " file://0010-driver-mctp-usb-set-tx_queue_len.patch"
