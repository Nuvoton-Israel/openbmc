SUMMARY = "DDR4 SI Standalone Test for NPCM7XX (Poleg) devices"
DESCRIPTION = "DDR4 SI Standalone Test for NPCM7XX (Poleg) devices"
HOMEPAGE = "https://github.com/medadyoung/DDR4-SI"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

FILENAME = "GFX-${PV}.bin"

S = "${WORKDIR}"

SRCREV = "c778925bf09b175a6a5e6f2b32bab8a7b4c52077"
SRC_URI = " \
    https://raw.githubusercontent.com/Nuvoton-Israel/openbmc-util/${SRCREV}/LICENSE;name=lic \
    https://github.com/Nuvoton-Israel/openbmc-util/releases/download/GFX-${PV}/gfx.bin;downloadfilename=${FILENAME};name=bin \
"

SRC_URI[lic.md5sum] = "b234ee4d69f5fce4486a80fdaf4a4263"
SRC_URI[bin.sha256sum] = "92e8a5d7b187def6d1db125dfb96b31ca0ee710a95b8cb26cd6a2cf227efdfcb"

inherit deploy

do_deploy () {
	install -D -m 644 ${WORKDIR}/${FILENAME} ${DEPLOYDIR}/GFX.bin
}

addtask deploy before do_build after do_compile
