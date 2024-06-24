FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://service-override.conf"

FILES:${PN}:append = " ${systemd_system_unitdir}/xyz.openbmc_project.LED.GroupManager.service.d/service-override.conf"

do_install:append () {
    rm -rf ${D}${datadir}/${PN}/*

    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.LED.GroupManager.service.d
    install -D -m 0644 ${WORKDIR}/service-override.conf \
      ${D}${systemd_system_unitdir}/xyz.openbmc_project.LED.GroupManager.service.d/
}
