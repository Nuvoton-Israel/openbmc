KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-5.15-OpenBMC"
LINUX_VERSION = "5.15.85"
SRCREV:npcm8xx = "9701d3eef021f3c49ac710f4b82d78d584dd1952"
SRCREV:npcm7xx = "c596e7c23e0b78d4af6232a14a609921a2d94066"

require linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://0017-drivers-i2c-workaround-for-i2c-slave-behavior.patch"

