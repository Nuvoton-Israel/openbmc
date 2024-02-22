SUMMARY = "nist linux selftest"
DESCRIPTION = "nist linux selftest tool"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

TARGET_CC_ARCH += "${LDFLAGS}"

S = "${WORKDIR}/git"
SRCBRANCH = "master"
SRC_URI = "git://github.com/Nuvoton-Israel/nist-linux-selftest;protocol=https;branch=${SRCBRANCH} \
           file://nist-linux-selftest.service \
          "

SRCREV = "5890ce57565df253c35a5478758a09a29df2b0e4"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "autoconf-archive-native"
DEPENDS += "systemd"
RDEPENDS:${PN} += "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nist-linux-selftest.service"

do_install() {
        install -Dm755 ${S}/nist-linux-selftest ${D}/${sbindir}/nist-linux-selftest
}
