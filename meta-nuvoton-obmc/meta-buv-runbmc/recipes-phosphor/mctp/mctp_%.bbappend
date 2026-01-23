FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append = " file://mctp-config"
SRC_URI:append = " file://setup-eid.conf"

FILES:${PN} += "${systemd_system_unitdir}/*"

do_install:append () {
    override_dir=${D}${systemd_system_unitdir}/mctpd.service.d
    install -d ${D}${systemd_system_unitdir}/mctpd.service.d

    install -m 0644 ${UNPACKDIR}/setup-eid.conf \
            ${override_dir}/setup-eid.conf

    install -d ${D}${libexecdir}/mctp

    install -m 0755 ${UNPACKDIR}/mctp-config \
            ${D}${libexecdir}/mctp/
}