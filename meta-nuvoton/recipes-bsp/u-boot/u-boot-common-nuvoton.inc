HOMEPAGE = "https://github.com/Nuvoton-Israel/u-boot"
SECTION = "bootloaders"
DEPENDS += "flex-native bison-native"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=30503fd321432fc713238f582193b78e"

UBRANCH = "npcm7xx-v2019.01"
UBRANCH_npcm8xx = "npcm8mnx-v2019.01_tmp"
SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH}"
SRCREV = "9033cd58bf7050e8aa9a6b08ba53ed8d72e17394"
SRCREV_npcm8xx = "4ab53889b09ec7adaeb0a8837810535156bf840d"

S = "${WORKDIR}/git"

PV .= "+${UBRANCH}+"
