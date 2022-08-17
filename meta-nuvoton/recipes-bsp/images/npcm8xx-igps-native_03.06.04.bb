SUMMARY = "Image Generation and Programming Scripts for NPCM8XX (Arbel) devices"
DESCRIPTION = "Image Generation and Programming Scripts for NPCM8XX (Arbel) devices"
HOMEPAGE = "https://github.com/Nuvoton-Israel/igps-npcm8xx"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = " \
    git://github.com/Nuvoton-Israel/igps-npcm8xx;branch=main;protocol=https \
    file://0001-Adjust-paths-for-use-with-Bitbake.patch \
"

# tag IGPS_03.06.04
SRCREV = "6b056bb97a8f0e677d196afb6704372cae8bdd5b"

S = "${WORKDIR}/git"

DEST = "${D}${datadir}/${BPN}"

do_install() {
	install -d ${DEST}
	install py_scripts/ImageGeneration/references/BootBlockAndHeader_${DEVICE_GEN}_${IGPS_MACHINE}.xml ${DEST}
	install py_scripts/ImageGeneration/references/UbootHeader_${DEVICE_GEN}.xml ${DEST}
	install py_scripts/ImageGeneration/inputs/BL31_AndHeader.xml ${DEST}
	install py_scripts/ImageGeneration/inputs/OpTeeAndHeader.xml ${DEST}
}

inherit native