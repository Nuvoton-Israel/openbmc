SUMMARY = "SMBIOS MDR version 2 service for Intel based platform"
DESCRIPTION = "SMBIOS MDR version 2 service for Intel based platfrom"

SRC_URI = "git://github.com/openbmc/smbios-mdr"
SRCREV = "9c362668c24153066f746393f12f3869e095d523"

SRC_URI += "file://0001-Notify-inventory-manager-that-a-interface-needs-adde.patch"
SRC_URI += "file://0002-remove-fno-rtti-cxx-flags.patch"
SRC_URI += "file://smbios2"
SRC_URI += "file://smbios-mdrv2.service"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"


LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit cmake pkgconfig
inherit systemd

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
    "
do_install_append() {
    install -d ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
    install -m 0644 ${WORKDIR}/smbios2 ${D}${localstatedir_nativesdk}/${base_libdir_nativesdk}/smbios
}

EXTRA_OECMAKE = "-DYOCTO=1"
