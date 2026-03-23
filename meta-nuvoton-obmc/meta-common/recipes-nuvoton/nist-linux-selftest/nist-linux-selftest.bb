SUMMARY = "nist linux selftest"
DESCRIPTION = "nist linux selftest tool"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

TARGET_CC_ARCH += "${LDFLAGS}"


SRCBRANCH = "master"
SRC_URI = "git://github.com/Nuvoton-Israel/nist-linux-selftest;protocol=https;branch=${SRCBRANCH} \
           file://nist-linux-selftest.service \
          "

SRCREV = "ec7f69943b565e179b6f2db80e7c9c403a26ade6"

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
