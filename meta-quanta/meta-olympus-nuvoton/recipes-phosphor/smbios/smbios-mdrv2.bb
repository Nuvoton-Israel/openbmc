SUMMARY = "SMBIOS MDR version 2 service for Intel based platform"
DESCRIPTION = "SMBIOS MDR version 2 service for Intel based platfrom"

SRC_URI = "git://git@github.com/Intel-BMC/mdrv2.git;protocol=ssh"
SRCREV = "5ae0c19064f010c9981cc90f4ddb2031887de4dc"

SRC_URI += "file://0001-Notify-inventory-manager-that-a-interface-needs-adde.patch"
SRC_URI += "file://smbios2"

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

do_install_append() {
    install -d ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
    install -m 0644 ${WORKDIR}/smbios2 ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
}
