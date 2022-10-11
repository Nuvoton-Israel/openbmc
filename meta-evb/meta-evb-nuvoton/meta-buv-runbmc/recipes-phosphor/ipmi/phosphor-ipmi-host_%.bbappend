inherit buv-entity-utils

FILESEXTRAPATHS:append:buv-runbmc := "${THISDIR}/${PN}:"

DEPENDS:append:buv-runbmc = " ${@entity_enabled(d, '', ' buv-runbmc-yaml-config')}"
EXTRA_OECONF:append:buv-runbmc = " ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-sensors.yaml')}"
EXTRA_OECONF:append:buv-runbmc = " ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-fru-read.yaml')}"
EXTRA_OECONF:append:buv-runbmc = " ${@entity_enabled(d, '', 'INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/buv-runbmc-yaml-config/ipmi-inventory-sensors.yaml')}"
EXTRA_OECONF:append:buv-runbmc = " --disable-i2c-whitelist-check"
EXTRA_OECONF:append:buv-runbmc = " --enable-sel_logger_clears_sel"

SRC_URI:append:buv-runbmc = " file://0001-Add-set-BIOS-version-support.patch"
SRC_URI:append:buv-runbmc = " file://0002-Add-SEL-add-command.patch"
SRC_URI:append:buv-runbmc = " file://0003-Add-sensor-type-command.patch"
SRC_URI:append:buv-runbmc = " file://0004-ipmi-warm-reset-command.patch"
SRC_URI:append:buv-runbmc = " file://0005-get-system-guid-command.patch"
SRC_URI:append:buv-runbmc = " file://0006-Add-SEL-time-set-command.patch"
SRC_URI:append:buv-runbmc = " file://0007-Force-self-test-OK.patch"
SRC_URI:append:buv-runbmc = " file://0008-Set-is-from-system-interface-return-false.patch"
SRC_URI:append:buv-runbmc = " file://0009-Add-SEL-event-after-SEL-clear.patch"
SRC_URI:append:buv-runbmc = " file://0010-Fix-duplicated-seesion-handle.patch"
SRC_URI:append:buv-runbmc = " file://0011-Add-reset-SEL.patch"
SRC_URI:append:buv-runbmc = " file://0012-dbus-sdr-do-not-replace-_-for-sensor-name.patch"
SRC_URI:append:buv-runbmc = " file://0013-Add-session-RemoteMACAddress-support.patch"
SRC_URI:append:buv-runbmc = " file://0014-add-server-type-and-oem-id-to-meet-MS-spec.patch"
SRC_URI:append:buv-runbmc = " file://0015-fix-percentage-type-show.patch"
SRC_URI:append:buv-runbmc = " file://0016-sensor-reading-optional-zero.patch"
SRC_URI:append:buv-runbmc = " file://0017-add-sensor-reading-factory-support.patch"
SRC_URI:append:buv-runbmc = " file://0018-add-oem-sel-support.patch"
SRC_URI:append:buv-runbmc = " file://0019-update-chassishandler-from-intel-oem-ipmi.patch"
SRC_URI:append:buv-runbmc = " file://0020-save-no-supported-boot-options.patch"
SRC_URI:append:buv-runbmc = " file://0021-set-channel-security-keys.patch"
SRC_URI:append:buv-runbmc = " file://0027-implement-chassis-acfail-status.patch"

PACKAGECONFIG:append:buv-runbmc = " ${@entity_enabled(d, 'dynamic-sensors', '')}"

# avoid build error after remove ipmi-fru
WHITELIST_CONF:buv-runbmc = "${S}/host-ipmid-whitelist.conf"

# support ipmi warm reset
FILES:${PN}:append:buv-runbmc = " ${systemd_system_unitdir}/phosphor-ipmi-host.service.d/ipmi-warm-reset.conf"
SRC_URI:append:buv-runbmc = " file://ipmi-warm-reset.conf"
SYSTEMD_SERVICE:${PN}:append:buv-runbmc = " phosphor-ipmi-warm-reset.target"

do_install:append:buv-runbmc() {
        install -d ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d
        install -m 0644 ${WORKDIR}/ipmi-warm-reset.conf \
                        ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d/ipmi-warm-reset.conf
}
