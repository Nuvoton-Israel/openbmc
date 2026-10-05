FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append = " file://mctp-config"
SRC_URI:append = " file://setup-eid.conf"
SRC_URI:append = " file://90-mctp.rules"

# Fix: static-EID endpoints report a UUID over MCTP but it never reaches
# D-Bus because the requested/received EID mismatch path publishes the peer
# (via change_peer_eid) before query_peer_properties() learns the UUID, and
# publish_peer() early-returns on the second call. Attach Common.UUID when it
# becomes known after the initial publish so spdmd can match inventory by UUID.
# Must be listed after 0002 (both touch publish_peer()).
SRC_URI:append:df-composite-eat = " file://0003-mctpd-attach-Common.UUID-when-learned-after-publish.patch"

FILES:${PN} += "${systemd_system_unitdir}/*"
FILES:${PN} += "${sysconfdir}/udev/rules.d/90-mctp.rules"
FILES:${PN} += "${@bb.utils.contains('MCTPD_ROLE', 'endpoint', '${sysconfdir}/mctpd.conf', '', d)}"

# mctpd role: "bus-owner" (default) or "endpoint". Override in conf/local.conf.
MCTPD_ROLE ??= "bus-owner"

SRC_URI:append:nuvoton = "${@bb.utils.contains('MCTPD_ROLE', 'endpoint', ' file://0001-mctpd-reply-to-Set-Endpoint-ID-before-querying-peer.patch', '', d)}"
SRC_URI:append = "${@bb.utils.contains('MCTPD_ROLE', 'endpoint', ' file://mctpd-endpoint.conf', '', d)}"

do_install:append () {
    override_dir=${D}${systemd_system_unitdir}/mctpd.service.d
    install -d ${D}${systemd_system_unitdir}/mctpd.service.d

    install -m 0644 ${UNPACKDIR}/setup-eid.conf \
            ${override_dir}/setup-eid.conf

    install -d ${D}${libexecdir}/mctp

    install -m 0755 ${UNPACKDIR}/mctp-config \
            ${D}${libexecdir}/mctp/

    install -d ${D}${sysconfdir}/udev/rules.d/
    install -m 0644 ${UNPACKDIR}/90-mctp.rules ${D}${sysconfdir}/udev/rules.d

    if [ "${MCTPD_ROLE}" = "endpoint" ]; then
        install -d ${D}${sysconfdir}
        install -m 0644 ${UNPACKDIR}/mctpd-endpoint.conf ${D}${sysconfdir}/mctpd.conf
    fi
}
