
# TODO: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "https://github.com/Nuvoton-Israel/npcm7xx-bootblock/releases/download/10.08.07/Poleg_bootblock_google.bin"
SRC_URI[md5sum] = "79d286ffc197ba1935073915c9ac2ac1"

SRCREV = "${AUTOREV}"

inherit deploy

BOOTBLOCK ?= "bootblock.bin"

do_deploy () {
	install -d ${DEPLOYDIR}
	install -m 644 ${WORKDIR}/Poleg_bootblock_google.bin ${DEPLOYDIR}/${BOOTBLOCK}
}

addtask deploy before do_build after do_compile
