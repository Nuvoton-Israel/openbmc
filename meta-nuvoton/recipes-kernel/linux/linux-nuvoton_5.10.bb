KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-5.10-OpenBMC"
LINUX_VERSION = "5.10.161"
SRCREV = "45ae05f0464f9bcdbf20200e9a64ef155874a16a"

require linux-nuvoton.inc
SRC_URI:append:nuvoton = " file://enable_emmc_510.cfg"
