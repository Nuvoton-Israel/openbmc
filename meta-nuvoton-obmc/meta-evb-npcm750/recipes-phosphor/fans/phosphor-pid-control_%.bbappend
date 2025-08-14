inherit entity-utils

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://config-evb-nuvoton.json \
    file://fan-default-speed.sh \
    file://fan-reboot-control.service \
    file://fan-boot-control.service \
    file://phosphor-pid-control_evb.service \
    file://phosphor-pid-control_evb_entity.service \
    "

FILES:${PN}:append = " \
    ${bindir}/fan-default-speed.sh \
    ${datadir}/swampd/config.json \
    "

RDEPENDS:${PN} += "bash"

SYSTEMD_SERVICE:${PN}:append = " \
    fan-reboot-control.service \
    fan-boot-control.service \
    "

# default recipe already include phosphor-pid-control.service

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${UNPACKDIR}/fan-default-speed.sh ${D}/${bindir}

    install -d ${D}${datadir}/swampd
    install -m 0644 -D ${UNPACKDIR}/config-evb-nuvoton.json \
        ${D}${datadir}/swampd/config.json

    install -d ${D}${systemd_unitdir}/system/

    ENTITY_MANAGER_ENABLE="${@entity_enabled(d, 'true', 'false')}"
    if [ "${ENTITY_MANAGER_ENABLE}" = "true" ]; then
        install -m 0644 ${UNPACKDIR}/phosphor-pid-control_evb_entity.service \
            ${D}${systemd_unitdir}/system/phosphor-pid-control.service
    else
        install -m 0644 ${UNPACKDIR}/phosphor-pid-control_evb.service \
            ${D}${systemd_unitdir}/system/phosphor-pid-control.service
    fi

    install -m 0644 ${UNPACKDIR}/fan-reboot-control.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${UNPACKDIR}/fan-boot-control.service \
        ${D}${systemd_unitdir}/system
}

EXTRA_OECONF:append = " --enable-configure-dbus=yes"
