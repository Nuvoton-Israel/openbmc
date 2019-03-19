FILESEXTRAPATHS_prepend := "${THISDIR}/linux-nuvoton:"

KBRANCH = "Poleg-4.17.04-OpenBMC"
LINUX_VERSION = "4.17.4"

DEPENDS += "phosphor-nuvoton-signing-key-native"
UBOOT_SIGN_KEYDIR = "${DEPLOY_DIR_IMAGE}/uboot_fitkey/"
UBOOT_SIGN_KEYNAME = "Nuvoton"

KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=git;branch=${KBRANCH}"
SRCREV = "c1cb34fb8353ae81983cc64ac8fd488f13e68075"

SRC_URI += "file://evb-npcm750.cfg"
SRC_URI += "file://enable-vcd-ece.cfg"
SRC_URI += "file://enable-configfs-hid.cfg"
SRC_URI += "file://001-partitions.patch"
SRC_URI += "file://enable-configfs-mstg.cfg"
SRC_URI += "file://0002-nbd-fix-reconnect.patch"
SRC_URI += "file://enable-i2cslave.cfg"
SRC_URI += "file://0001-meta-evb-npcm750-enable-i2c-slave-function.patch"
