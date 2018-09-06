LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://github.com/Nuvoton-Israel/npcm7xx-flashtool.git;branch=nuvoton-evb;"
SRC_URI[md5sum] = "61ea43d858eca22d0e2d265904ec5eef"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

EXTRA_OEMAKE = "'CC=${CC}' 'RANLIB=${RANLIB}' 'AR=${AR}' 'CFLAGS=${CFLAGS} -I${S}/include -DWITHOUT_XATTR' 'BUILDDIR=${S}'"

do_install () {
	oe_runmake install DESTDIR=${D} bindir=${bindir}
}

inherit native
