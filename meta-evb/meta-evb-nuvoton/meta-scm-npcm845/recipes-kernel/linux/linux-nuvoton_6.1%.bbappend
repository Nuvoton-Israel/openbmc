FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:scm-npcm845 = " file://nuvoton-npcm845-scm.dts;subdir=git/arch/${ARCH}/boot/dts/nuvoton "
SRC_URI:append:scm-npcm845 = " file://0001-kernel-scm-dts.patch"
SRC_URI:append:scm-npcm845 = " file://0002-rtl8211f-customized-led.patch"
SRC_URI:append:scm-npcm845 = " file://scm-npcm845.cfg"
SRC_URI:append:scm-npcm845 = " file://enable-v4l2.cfg"

SRC_URI:append:m1120-c2195 = " file://m1120-c219b.dts;subdir=git/arch/${ARCH}/boot/dts/nuvoton"
SRC_URI:append:m1120-c2195 = " file://0001-kernel-m1120-dts.patch"
SRC_URI:append:m1120-c2195 = " file://0006-Add-DVO-slew-rate-and-remove-smb11-default-pinctrl.patch"
SRC_URI:append:m1120-c2195 = " file://0102-Add-driver-for-HDC302x.patch"
SRC_URI:append:m1120-c2195 = " file://m1120.cfg"
SRC_URI:append:m1120-c2195 = " file://0001-i2c-npcm7xx-initial-M1120-I2C-segment.patch"
