KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-6.18-OpenBMC"
LINUX_VERSION = "6.18.33"
SRCREV = "9cec0292ec35cf0eb986389c844acd1353d7aae1"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"
