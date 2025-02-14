FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://mctp-config"
SRC_URI:append = " file://setup-local-eid.conf"
SRC_URI:append = " file://90-mctp-usb0-network.rules"
SRC_URI:append = " file://mctpd.service"

SRC_URI:append = " file://0500-Support-get-static-eid-config-from-entity-manager.patch"
SRC_URI:append = " file://0501-Modified-the-type-of-NetworkId-to-uint32_t.patch"
SRC_URI:append = " file://0502-mctpd-Add-AssignEndpointStatic-dbus-interface.patch"
SRC_URI:append = " file://0503-Add-method-for-setting-up-MCTP-EID-by-config-path.patch"
SRC_URI:append = " file://0504-mctpd-fix-mctpd-crash-issue.patch"
SRC_URI:append = " file://0505-mctpd-supprot-usb-binding.patch"
SRC_URI:append = " file://0506-add-mctp-flash.patch"

SYSTEMD_SERVICE:${PN}:append = " mctpd.service"

FILES:${PN} += "${systemd_system_unitdir}/*"

do_install:append () {
        install -d ${D}${systemd_system_unitdir}

        override_dir=${D}${systemd_system_unitdir}/mctpd.service.d
        install -d ${D}${systemd_system_unitdir}/mctpd.service.d

        install -m 0644 ${WORKDIR}/mctpd.service \
                ${D}${systemd_system_unitdir}/mctpd.service

        install -m 0644 ${WORKDIR}/setup-local-eid.conf \
                ${override_dir}/setup-local-eid.conf

        install -d ${D}${libexecdir}/mctp

        install -m 0755 ${WORKDIR}/mctp-config \
                ${D}${libexecdir}/mctp/

        install -d ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/90-mctp-usb0-network.rules ${D}${sysconfdir}/udev/rules.d/90-mctp-usb0-network.rules
}
