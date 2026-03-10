KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-5.10-OpenBMC"
LINUX_VERSION = "5.10.222"
SRCREV = "9ae1ad4626d44ef679883ac62111460d83ebc089"

SRC_URI:append:nuvoton = " file://enable_emmc_510.cfg"
SRC_URI:append:nuvoton = " file://disalbe_stackprotector.cfg"
SRC_URI:append:nuvoton = " file://enable-pcie-vdm.cfg"
SRC_URI:append:nuvoton = " file://enable-usb-legacy.cfg"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc
