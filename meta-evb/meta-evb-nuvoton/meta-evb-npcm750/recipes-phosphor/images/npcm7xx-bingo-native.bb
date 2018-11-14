LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

inherit npcm7xx-image

do_install[depends] += "npcm7xx-igps-native:do_populate_sysroot"

SRC_URI = "git://github.com/nuvoton-israel/bingo.git;"
SRC_URI[md5sum] = "${AUTOREV}"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

do_install () {

	# ${IGPS_IMAGE_GENERATION_DIR} was already created by npcm7xx-igps-native  
	install deliverables/linux/Release/bingo ${IGPS_IMAGE_GENERATION_DIR}/bingo
}

inherit native
