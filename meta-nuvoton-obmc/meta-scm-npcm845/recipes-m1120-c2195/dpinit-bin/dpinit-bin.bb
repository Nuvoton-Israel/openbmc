SUMMARY = "Display port init app"
DESCRIPTION = "Display port init app"
HOMEPAGE = ""
LICENSE = "CLOSED"

#inherit
inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "systemd"

INSANE_SKIP:${PN}:append = " already-stripped"

SRC_URI = "file://dpinit \
           file://dpinit.service \
          "

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

SYSTEMD_SERVICE:${PN} = "dpinit.service"

do_install() {
    install -m 0755 -d ${D}${bindir}
    install -m 0755 ${UNPACKDIR}/dpinit ${D}/usr/bin/
}
