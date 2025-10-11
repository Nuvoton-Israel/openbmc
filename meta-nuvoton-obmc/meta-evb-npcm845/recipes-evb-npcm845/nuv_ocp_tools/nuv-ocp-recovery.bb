SUMMARY = "OCP Recovery Tool"
DESCRIPTION = "This is a package for a tool that Caplitra Nuvoton OCP recovery"
PR = "r1"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit systemd
inherit autotools pkgconfig

DEPENDS += "systemd sdbusplus nlohmann-json libgpiod libdbus-c++ i2cdev i3c-tools"

RDEPENDS:${PN} += "libgpiod libdbus-c++ i2cdev"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

SRC_URI = "file://src/nuv_ocp_recovery.cpp \
           file://src/Makefile.am \
           file://Makefile.am \
           file://configure.ac \
           file://COPYING.MIT \
          "

do_install() {
    install -Dm755 ${WORKDIR}/build/src/nuv_ocp_recovery ${D}/${sbindir}/nuv_ocp_recovery
}
