HOMEPAGE = "https://github.com/Nuvoton-Israel/u-boot"
SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=5a7450c57ffe5ae63fd732446b988025"

UBRANCH = "npcm-v2021.04"
SRCREV = "6276a5d430d0287a05a5e978fdd03010463c5d92"

SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH};protocol=https"

S = "${WORKDIR}/git"

PV .= "+${UBRANCH}+"
