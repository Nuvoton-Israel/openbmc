KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-6.12-OpenBMC"
LINUX_VERSION = "6.12.63"
SRCREV = "88e741e1535d9eea546612ad3d104925dd80fcea"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"
