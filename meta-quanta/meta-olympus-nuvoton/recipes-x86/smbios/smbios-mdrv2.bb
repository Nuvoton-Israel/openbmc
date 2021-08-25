inherit entity-utils
SUMMARY = "SMBIOS MDR version 2 service for Intel based platform"
DESCRIPTION = "SMBIOS MDR version 2 service for Intel based platfrom"

SRC_URI = "git://github.com/openbmc/smbios-mdr"
SRCREV = "d23b84a7eb2be944b12e6539cf627f595b299fda"

SRC_URI_append = " ${@entity_enabled(d, '', 'file://0004-smbios-add-functional-property-for-sdr-dimm-test.patch')}"
SRC_URI += "file://smbios2"
SRC_URI += "file://smbios-mdrv2.service"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"


LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit cmake pkgconfig
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE_${PN} += "smbios-mdrv2.service"
SYSTEMD_SERVICE_${PN} += "xyz.openbmc_project.cpuinfo.service"

DEPENDS += " \
    autoconf-archive-native \
    boost \
    systemd \
    sdbusplus \
    phosphor-dbus-interfaces \
    phosphor-logging \
    libpeci \
    i2c-tools \
    phosphor-ipmi-blobs \
    "
do_install_append() {
    install -d ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
    install -m 0644 ${WORKDIR}/smbios2 ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/smbios-mdrv2.service ${D}${systemd_system_unitdir}
}

EXTRA_OECMAKE = "-DYOCTO=1"
EXTRA_OECMAKE += "-DIPMI_BLOB=OFF"

PACKAGECONFIG ??= "${@bb.utils.filter('DISTRO_FEATURES', 'smbios-no-dimm', d)}"
PACKAGECONFIG[smbios-no-dimm] = "-DDIMM_DBUS=OFF, -DDIMM_DBUS=ON"
