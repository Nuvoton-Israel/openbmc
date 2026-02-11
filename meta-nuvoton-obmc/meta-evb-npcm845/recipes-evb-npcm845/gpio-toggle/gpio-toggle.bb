FILESEXTRAPATHS:append := "${THISDIR}/files:"
SUMMARY = "PWM to TACH Simulator"
DESCRIPTION = "Simulates fan tachometer output based on PWM duty cycle input"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "systemd libgpiod"
RDEPENDS:${PN} += "libsystemd libgpiod bash"

SRC_URI = "file://pwm_tach_sim.c \
           file://pwm_capture.c \
           file://Makefile \
           file://pwm-tach-sim.service \
           file://gpio_toggle.sh \
           file://pwm_test.sh \
           file://closed_loop_test.sh"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

# Ensure pkg-config finds libgpiod
EXTRA_OEMAKE = "CC='${CC}' CFLAGS='${CFLAGS} -I${STAGING_INCDIR}' LDFLAGS='${LDFLAGS} -L${STAGING_LIBDIR} -lgpiod'"

do_compile() {
    cd ${UNPACKDIR}
    oe_runmake
}

do_install() {
    # Install the C programs
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/pwm_tach_sim ${D}${sbindir}/
    install -m 0755 ${UNPACKDIR}/pwm_capture ${D}${sbindir}/
    
    # Also install the simple bash script for manual testing
    install -m 0755 ${UNPACKDIR}/gpio_toggle.sh ${D}${sbindir}/
    
    # Install test scripts
    install -m 0755 ${UNPACKDIR}/pwm_test.sh ${D}${sbindir}/
    install -m 0755 ${UNPACKDIR}/closed_loop_test.sh ${D}${sbindir}/

    # Install systemd service
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${UNPACKDIR}/pwm-tach-sim.service ${D}${systemd_unitdir}/system/
}

NATIVE_SYSTEMD_SUPPORT = "1"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "pwm-tach-sim.service"

inherit systemd
