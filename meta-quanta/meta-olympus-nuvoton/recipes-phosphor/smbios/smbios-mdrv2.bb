SUMMARY = "SMBIOS MDR version 2 service for Intel based platform"
DESCRIPTION = "SMBIOS MDR version 2 service for Intel based platfrom"

SRC_URI = "git://git@github.com/Intel-BMC/mdrv2.git;protocol=ssh"
SRCREV = "d1fc2546cba818388fbef22f50dce6ef17885ff5"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit cmake pkgconfig
inherit obmc-phosphor-systemd

SYSTEMD_SERVICE_${PN} += "smbios-mdrv2.service"

DEPENDS += " \
    autoconf-archive-native \
    boost \
    systemd \
    sdbusplus \
    sdbusplus-native \
    phosphor-dbus-interfaces \
    phosphor-dbus-interfaces-native \
    phosphor-logging \
    "
