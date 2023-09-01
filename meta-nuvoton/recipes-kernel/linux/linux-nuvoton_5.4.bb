# Only for test purpose

KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "Poleg-5.4-OpenBMC"
LINUX_VERSION = "5.4.80"
SRCREV = "9527d021b546859a5847404b4aa56fd3e63b5a4d"

require linux-nuvoton.inc
SRC_URI:append:nuvoton = " file://enable_emmc_510.cfg"
SRC_URI:append:nuvoton = " file://disalbe_stackprotector.cfg"
SRC_URI:append:nuvoton = " file://enable-pcie-vdm.cfg"
SRC_URI:append:nuvoton = " file://enable-usb-legacy.cfg"

LIC_FILES_CHKSUM = "file://COPYING;md5=bbea815ee2795b2f4230826c0c6b8814"
