
KBRANCH ?= "NPCM-5.10-OpenBMC"
LINUX_VERSION ?= "5.10.161"
SRCREV = "73b95b816cc12e7dcd06b3dbdcdb61cdce636814"

require linux-nuvoton.inc

#SRC_URI:append:nuvoton = " file://0004-driver-ncsi-replace-del-timer-sync.patch"
#SRC_URI:append:nuvoton = " file://0015-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"
SRC_URI:append:nuvoton = " file://0017-drivers-i2c-workaround-for-i2c-slave-behavior.patch"
