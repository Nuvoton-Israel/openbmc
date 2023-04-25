FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton-510:${THISDIR}/linux-nuvoton:"

SRC_URI:append:scm-npcm845 = " file://0004-kernel-scm-dts.patch"
SRC_URI:append:scm-npcm845 = " file://0012-rtl8211f-customized-led.patch"
SRC_URI:append:scm-npcm845 = " file://scm-npcm845.cfg"
SRC_URI:append:scm-npcm845 = " file://enable-v4l2.cfg"
