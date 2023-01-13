FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:scm-npcm845 = " file://scm-npcm845.cfg"
SRC_URI:append:scm-npcm845 = " file://0003-net-phy-realtek-add-soft_reset.patch"
SRC_URI:append:scm-npcm845 = " file://0004-kernel-scm-dts.patch"
SRC_URI:append:scm-npcm845 = " file://0005-p2011-skip-status-check.patch"
SRC_URI:append:scm-npcm845 = " file://0007-hwmon-sbtsi-Add-basic-support-for-SB-TSI-sensors.patch"
SRC_URI:append:scm-npcm845 = " file://0008-dts-scm-npcm845-add-gpio-name-P3V_BAT_EN.patch"
SRC_URI:append:scm-npcm845 = " file://0010-DTS-Add-sensor-TMP461.patch"
SRC_URI:append:scm-npcm845 = " file://0011-updaye-amd-apml-dirver.patch"
SRC_URI:append:scm-npcm845 = " file://0012-rtl8211f-customized-led.patch"
SRC_URI:append:scm-npcm845 = " file://0013-Add-pmbus-driver-for-MAX16550.patch"
SRC_URI:append:scm-npcm845 = " file://0015-device-tree-optee-enable.patch"
SRC_URI:append:scm-npcm845 = " file://0017-dts-scm-npcm845-add-tip-mailbox-support.patch"

SRC_URI:append:scm-npcm845 = " file://enable-v4l2-kvm.cfg"
#SRC_URI:append:scm-npcm845 = " file://enable-legacy-kvm.cfg"
#SRC_URI:append:scm-npcm845 = " file://1111-dts-enable-legacy-kvm.patch"
