SUMMARY = "A cc_dry2 test program"
DESCRIPTION = "The copy test program."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI += "file://cc_dry2 \
            file://i2c_slave_rw \
            file://setup_test.sh"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"
INSANE_SKIP:${PN} = "ldflags"

do_install () {
	install -d ${D}${bindir}/
	install ${UNPACKDIR}/cc_dry2 ${D}${bindir}
	install ${UNPACKDIR}/i2c_slave_rw ${D}${bindir}
	install ${UNPACKDIR}/setup_test.sh ${D}${bindir}
}
