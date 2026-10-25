SUMMARY = "OBMF-ICP driver-level functional and stress test"
DESCRIPTION = "Exercises the I2C, GPIO, SPI and Serial channels of an \
OBMF-ICP device through the BMC obmf driver, runs them in parallel and \
optionally rebinds the driver, then checks the kernel log. Read-only \
towards the platform unless asked otherwise; see obmf-stress -h."

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://obmf-stress"

S = "${UNPACKDIR}"

RDEPENDS:${PN} = "i2c-tools libgpiod-tools"

do_install() {
	install -d ${D}${bindir}
	install -m 0755 ${UNPACKDIR}/obmf-stress ${D}${bindir}
}
