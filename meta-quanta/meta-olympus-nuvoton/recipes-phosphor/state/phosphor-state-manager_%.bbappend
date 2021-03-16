FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://0001-Use-pgood-to-check-host-stat.patch"
SRC_URI_append_olympus-nuvoton = " file://0002-add-support-to-record-last-bmc-reboot-cause.patch"
SRC_URI_append_olympus-nuvoton = " file://phosphor-reset-host-check@.service"

SYSTEMD_SERVICE_${PN}_append_olympus-nuvoton = " phosphor-reset-host-check@.service"

HOST_SHUT_TMPL = "obmc-host-shutdown@{0}.target"
HOST_WARMREBOOT_TGTFMT = "obmc-host-warm-reboot@{0}.target"
HOST_SHUT_FMT = "../${HOST_SHUT_TMPL}:${HOST_WARMREBOOT_TGTFMT}.requires/${HOST_SHUT_TMPL}"
SYSTEMD_LINK_${PN}-host += "${@compose_list(d, 'HOST_SHUT_FMT', 'OBMC_HOST_INSTANCES')}"

pkg_postinst_${PN}-obmc-targets_append() {
    LINK="$D$systemd_system_unitdir/obmc-host-warm-reboot@0.target.requires/xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"
    rm $LINK
}

DEPENDS += "i2c-tools"

do_install_append_olympus-nuvoton() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-reset-host-check@.service \
        ${D}${systemd_unitdir}/system
}
