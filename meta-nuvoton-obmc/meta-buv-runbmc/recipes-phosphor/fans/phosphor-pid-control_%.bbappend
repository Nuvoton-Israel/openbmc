FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

inherit entity-utils
SRC_URI:append:buv-runbmc = " file://config-buv-nuvoton.json"
SRC_URI:append:buv-runbmc = " \
    file://fan-default-speed.sh \
    file://fan-reboot-control.service \
    file://fan-boot-control.service \
    "
SRC_URI:append:buv-runbmc = " \
    ${@entity_enabled(d, '', 'file://phosphor-pid-control_buv.service')}"

FILES:${PN}:append:buv-runbmc = " ${bindir}/fan-default-speed.sh"
FILES:${PN}:append:buv-runbmc = " \
    ${@entity_enabled(d, '', '${datadir}/swampd/config.json')}"

RDEPENDS:${PN} += "bash"

SYSTEMD_SERVICE:${PN}:append:buv-runbmc = " fan-reboot-control.service"
SYSTEMD_SERVICE:${PN}:append:buv-runbmc = " fan-boot-control.service"
# default recipe already include phosphor-pid-control.service

is_entity = "${@entity_enabled(d, 'yes', '')}"

do_install:append:buv-runbmc() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/fan-default-speed.sh ${D}/${bindir}

    if [ -z "${is_entity}" ];then
        install -m 0644 -D ${UNPACKDIR}/config-buv-nuvoton.json \
            ${D}${datadir}/swampd/config.json
    fi

    install -d ${D}${systemd_unitdir}/system/
    if [ -z "${is_entity}" ];then
        install -m 0644 ${UNPACKDIR}/phosphor-pid-control_buv.service \
            ${D}${systemd_unitdir}/system/phosphor-pid-control.service
    fi
    install -m 0644 ${UNPACKDIR}/fan-reboot-control.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/fan-boot-control.service \
        ${D}${systemd_unitdir}/system
}

EXTRA_OECONF:append:buv-runbmc = " \
    ${@entity_enabled(d, '--enable-configure-dbus=yes')}"
