SRC_URI_remove = "git://github.com/openbmc/phosphor-host-ipmid"
SRC_URI_prepend = "git://github.com/Nuvoton-Israel/phosphor-host-ipmid"

SRCREV := "fc57f58936f1af5b94c25d113ef92932efb2ebc9"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRC_URI_append = " file://phosphor-ipmi-host.service"
SRC_URI_append = " file://xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"
SRC_URI_append = " file://0001-add-kcs1-object-path.patch"

SYSTEMD_SERVICE_${PN}_append = " phosphor-ipmi-host.service"
SYSTEMD_SERVICE_${PN}_append = " xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"

do_install_append() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.service \
        ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service \
        ${D}${systemd_unitdir}/system
}

