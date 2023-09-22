KSRC ?= "git://gbmc.googlesource.com/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "gbmc-5.15"
LINUX_VERSION = "5.15.108"
SRCREV = "1720a480503b8bcf69419c11af5fdaf54fa43d03"

require linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://0017-drivers-i2c-workaround-for-i2c-slave-behavior.patch"
