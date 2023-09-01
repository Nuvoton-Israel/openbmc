FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append:nuvoton = " file://0001-Add-mctp-discovery-command.patch"
SRC_URI:append:nuvoton = " file://mctpd.service"
SRC_URI:append:nuvoton = " file://mctp-config.sh"

DEPENDS += "i2c-tools"

do_install:append () {
    if ${@bb.utils.contains('PACKAGECONFIG', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        install -d ${D}${datadir}/mctp
        install -m 0644 ${WORKDIR}/mctpd.service \
            ${D}${systemd_system_unitdir}
        install -m 0755 ${WORKDIR}/mctp-config.sh \
            ${D}${datadir}/mctp/
    fi
}
