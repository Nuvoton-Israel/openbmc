inherit entity-utils

FILESEXTRAPATHS:append:scm-npcm845 := "${THISDIR}/${PN}:"

DEPENDS:append:scm-npcm845 = " ${@entity_enabled(d, '', ' scm-npcm845-yaml-config')}"
RDEPENDS:${PN}:remove:scm-npcm845 = "clear-once"
EXTRA_OECONF:append:scm-npcm845 = " ${@entity_enabled(d, '', 'SENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/scm-npcm845-yaml-config/ipmi-sensors.yaml')}"
EXTRA_OECONF:append:scm-npcm845 = " ${@entity_enabled(d, '', 'FRU_YAML_GEN=${STAGING_DIR_HOST}${datadir}/scm-npcm845-yaml-config/ipmi-fru-read.yaml')}"
EXTRA_OECONF:append:scm-npcm845 = " ${@entity_enabled(d, '', 'INVSENSOR_YAML_GEN=${STAGING_DIR_HOST}${datadir}/scm-npcm845-yaml-config/ipmi-inventory-sensors.yaml')}"
EXTRA_OECONF:append:scm-npcm845 = " --disable-i2c-whitelist-check"
EXTRA_OECONF:append:scm-npcm845 = " --enable-sel_logger_clears_sel"

SRC_URI:append:scm-npcm845 = " file://0001-Add-set-BIOS-version-support.patch"
SRC_URI:append:scm-npcm845 = " file://0002-Add-SEL-add-command.patch"
SRC_URI:append:scm-npcm845 = " file://0003-Add-sensor-type-command.patch"
SRC_URI:append:scm-npcm845 = " file://0004-ipmi-warm-reset-command.patch"
SRC_URI:append:scm-npcm845 = " file://0005-get-system-guid-command.patch"
SRC_URI:append:scm-npcm845 = " file://0006-Add-SEL-time-set-command.patch"
SRC_URI:append:scm-npcm845 = " file://0007-Force-self-test-OK.patch"
SRC_URI:append:scm-npcm845 = " file://0008-Set-is-from-system-interface-return-false.patch"
SRC_URI:append:scm-npcm845 = " file://0009-Add-SEL-event-after-SEL-clear.patch"
SRC_URI:append:scm-npcm845 = " file://0010-Fix-duplicated-seesion-handle.patch"
SRC_URI:append:scm-npcm845 = " file://0011-Add-reset-SEL.patch"
SRC_URI:append:scm-npcm845 = " file://0012-dbus-sdr-do-not-replace-_-for-sensor-name.patch"
SRC_URI:append:scm-npcm845 = " file://0013-Add-session-RemoteMACAddress-support.patch"
SRC_URI:append:scm-npcm845 = " file://0014-add-server-type-and-oem-id-to-meet-MS-spec.patch"
SRC_URI:append:scm-npcm845 = " file://0015-fix-percentage-type-show.patch"
SRC_URI:append:scm-npcm845 = " file://0016-sensor-reading-optional-zero.patch"
SRC_URI:append:scm-npcm845 = " file://0017-add-sensor-reading-factory-support.patch"
SRC_URI:append:scm-npcm845 = " file://0018-add-oem-sel-support.patch"
SRC_URI:append:scm-npcm845 = " file://0019-update-chassishandler-from-intel-oem-ipmi.patch"
SRC_URI:append:scm-npcm845 = " file://0020-save-no-supported-boot-options.patch"
SRC_URI:append:scm-npcm845 = " file://0021-set-channel-security-keys.patch"

PACKAGECONFIG:append:scm-npcm845 = " ${@entity_enabled(d, 'dynamic-sensors', '')}"

# avoid build error after remove ipmi-fru
WHITELIST_CONF:scm-npcm845 = "${S}/host-ipmid-whitelist.conf"

# support ipmi warm reset
FILES:${PN}:append:scm-npcm845 = " ${systemd_system_unitdir}/phosphor-ipmi-host.service.d/ipmi-warm-reset.conf"
SRC_URI:append:scm-npcm845 = " file://ipmi-warm-reset.conf"
SYSTEMD_SERVICE:${PN}:append:scm-npcm845 = " phosphor-ipmi-warm-reset.target"

do_install:append:scm-npcm845() {
        install -d ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d
        install -m 0644 ${WORKDIR}/ipmi-warm-reset.conf \
                        ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d/ipmi-warm-reset.conf
}
