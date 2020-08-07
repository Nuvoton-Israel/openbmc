FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

inherit buv-entity-utils
SRC_URI_append_buv-runbmc = " file://config-buv-nuvoton.json"
SRC_URI_append_buv-runbmc = " \
    file://fan-default-speed.sh \
    file://fan-reboot-control.service \
    file://fan-boot-control.service \
    "
SRC_URI_append_buv-runbmc = " \
    ${@entity_enabled(d, '', 'file://phosphor-pid-control.service')}"

FILES_${PN}_append_buv-runbmc = " ${bindir}/fan-default-speed.sh"
FILES_${PN}_append_buv-runbmc = " \
    ${@entity_enabled(d, '', '${datadir}/swampd/config.json')}"

RDEPENDS_${PN} += "bash"

SYSTEMD_SERVICE_${PN}_append_buv-runbmc = " fan-reboot-control.service"
SYSTEMD_SERVICE_${PN}_append_buv-runbmc = " fan-boot-control.service"
# default recipe already include phosphor-pid-control.service

do_install_append_buv-runbmc() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/fan-default-speed.sh ${D}/${bindir}

    if [ "${DISTRO}" != "buv-entity" ];then
        install -d ${D}${datadir}/swampd
        install -m 0644 -D ${WORKDIR}/config-buv-nuvoton.json \
            ${D}${datadir}/swampd/config.json
    fi

    install -d ${D}${systemd_unitdir}/system/
    if [ "${DISTRO}" != "buv-entity" ];then
        install -m 0644 ${WORKDIR}/phosphor-pid-control.service \
            ${D}${systemd_unitdir}/system
    fi
    install -m 0644 ${WORKDIR}/fan-reboot-control.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/fan-boot-control.service \
        ${D}${systemd_unitdir}/system
}

EXTRA_OECONF_append_buv-runbmc = " \
    ${@entity_enabled(d, '--enable-configure-dbus=yes')}"
