HOMEPAGE = "https://github.com/Nuvoton-Israel/u-boot"
SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=30503fd321432fc713238f582193b78e"
LIC_FILES_CHKSUM:npcm8xx = "file://Licenses/README;md5=5a7450c57ffe5ae63fd732446b988025"

UBRANCH = "npcm7xx-v2019.01"
SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH}"
SRCREV = "c11d9a81eadfb9b3c4e53acba1a97a13924b6d88"

UBRANCH:npcm8xx = "npcm-v2021.04"
SRCREV:npcm8xx = "5adc64c7d8f919637a5be92749bcdbba4770ee5c"

SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH}"

S = "${WORKDIR}/git"

PV .= "+${UBRANCH}+"
