FILESEXTRAPATHS:prepend := "${THISDIR}:"
DESCRIPTION = "Early OOM Daemon for Linux"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=875c33872f2633c48ce20e87d8cd3270"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "systemd"

RDEPENDS:${PN} += "bash"

SRC_URI = "git://github.com/rfjakob/earlyoom.git;branch=master;protocol=https \
          "
SRCREV = "90f1a6704e505d2b3d41dcc1677e23af80d6319a"
S = "${WORKDIR}/git"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "earlyoom.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/earlyoom.service ${D}${systemd_system_unitdir}
    install -d ${D}/usr/local/bin
    install -m 0755 ${S}/earlyoom ${D}/usr/local/bin/
}

FILES:${PN} += "/usr/local/bin/earlyoom"
