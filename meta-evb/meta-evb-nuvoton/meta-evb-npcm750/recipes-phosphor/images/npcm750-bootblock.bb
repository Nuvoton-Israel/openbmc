# TODO: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit npcm7xx-image

SRC_URI = "git://github.com/Nuvoton-Israel/npcm7xx-bootblock;protocol=git"
SRC_URI[md5sum] = "cf8daa5f4636ed1ff952618e435af028"

SRCREV = "10.09.05"

S = "${WORKDIR}/git"

inherit deploy

do_deploy () {
	install -d ${DEPLOYDIR}
	install -m 644 Poleg_bootblock.bin ${DEPLOYDIR}/
}

addtask deploy before do_build after do_compile
