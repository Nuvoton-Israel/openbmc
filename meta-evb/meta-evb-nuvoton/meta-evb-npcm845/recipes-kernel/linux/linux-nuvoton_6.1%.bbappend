FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:evb-npcm845 = " file://evb-npcm845.cfg"
SRC_URI:append:evb-npcm845 = " file://enable-v4l2.cfg"
SRC_URI:append:evb-npcm845 = " file://luks.cfg"

SRC_URI:append:evb-npcm845 = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
# SRC_URI:append:evb-npcm845 = " file://0016-support-CPLD-UART-16450.patch"
# SRC_URI:append:evb-npcm845 = " file://0002-dts-nuvoton-evb-npcm845-boot-from-fiu0-cs1.patch"

# for i3c slave test
# SRC_URI:append:evb-npcm845 = " file://0001-dts-i3c-slave.patch"
# SRC_URI:append:evb-npcm845 = " file://i3c_mctp.cfg"

# for mctp i2c test
# SRC_URI:append:evb-npcm845 = " file://0001-dts-mctp-i2c-controller.patch"
# SRC_URI:append:evb-npcm845 = " file://mctp.cfg"
