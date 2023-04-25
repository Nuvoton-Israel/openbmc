KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-5.15-OpenBMC"
LINUX_VERSION = "5.15.85"
SRCREV:npcm8xx = "9701d3eef021f3c49ac710f4b82d78d584dd1952"
SRCREV:npcm7xx = "91140a4c93b3d314a2865059645d7d57e5ec6e1e"

require linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://0003-i2c-nuvoton-npcm750-runbmc-integrate-the-slave-mqueu.patch"
SRC_URI:append:nuvoton = " file://0017-drivers-i2c-workaround-for-i2c-slave-behavior.patch"

