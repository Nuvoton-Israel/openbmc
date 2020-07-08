SUMMARY = "DDR4 SI Standalone Test for NPCM7XX (Poleg) devices"
DESCRIPTION = "DDR4 SI Standalone Test for NPCM7XX (Poleg) devices"
HOMEPAGE = "https://github.com/Nuvoton-Israel/openbmc-util"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

FILENAME = "DDRSI-${PV}.bin"

S = "${WORKDIR}"

SRCREV = "c778925bf09b175a6a5e6f2b32bab8a7b4c52077"
SRC_URI = " \
    https://raw.githubusercontent.com/Nuvoton-Israel/openbmc-util/${SRCREV}/LICENSE;name=lic \
    https://github.com/Nuvoton-Israel/openbmc-util/releases/download/DDRSI-${PV}/DDRSI.bin;downloadfilename=${FILENAME};name=bin \
"

SRC_URI[lic.md5sum] = "b234ee4d69f5fce4486a80fdaf4a4263"
SRC_URI[bin.sha256sum] = "9c8c2c7a1533d0eff6e9e64f5e150136973df84c67bf2711f1cc7065728ee099"

inherit deploy

do_deploy () {
	install -D -m 644 ${WORKDIR}/${FILENAME} ${DEPLOYDIR}/DDRSI.bin
}

addtask deploy before do_build after do_compile
