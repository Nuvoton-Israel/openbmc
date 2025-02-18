# Only for test purpose

KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "Poleg-5.4-OpenBMC"
LINUX_VERSION = "5.4.80"
SRCREV = "d523d4bca17b9196b840c54fa0bc1627140c29c2"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://enable_emmc_510.cfg"
SRC_URI:append:nuvoton = " file://disalbe_stackprotector.cfg"
SRC_URI:append:nuvoton = " file://enable-pcie-vdm.cfg"
SRC_URI:append:nuvoton = " file://enable-usb-legacy.cfg"

SRC_URI:append:nuvoton = " file://0001-vdm-debug.patch"

LIC_FILES_CHKSUM = "file://COPYING;md5=bbea815ee2795b2f4230826c0c6b8814"
