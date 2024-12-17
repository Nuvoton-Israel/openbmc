LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:= " file://fan_init.sh"
SRC_URI:append:= " file://fan_init.service"

FILES:${PN} = " ${bindir}/fan_init.sh"

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

DEPENDS += "systemd"
RDEPENDS:${PN} += "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " fan_init.service"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/fan_init.sh ${D}/${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/fan_init.service \
        ${D}${systemd_system_unitdir}
}

inherit systemd
