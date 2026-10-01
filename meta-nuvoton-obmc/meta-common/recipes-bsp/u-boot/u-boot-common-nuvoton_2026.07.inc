HOMEPAGE = "https://github.com/Nuvoton-Israel/u-boot"
SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=2ca5f2c35c8cc335f0a19756634782f1"

UBRANCH = "npcm-v2026.07"
SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH};protocol=https"
SRCREV = "3e3eed89232dc95e15f611ff6fcc0d6637f2dcd1"

PV = "v2026.07+git${SRCPV}"
