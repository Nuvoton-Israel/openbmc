SUMMARY = "MCTP Daemon"
DESCRIPTION = "Implementation of MCTP (DTMF DSP0236)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.applications.mctpd.git;protocol=ssh;branch=openbmc/release/birchstream/common"
SRCREV = "a211558c2aaad1dddb893a3bd820c2b84698ab8e"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

OECMAKE_SOURCEPATH = "${S}"

inherit cmake pkgconfig systemd

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    libmctp-intel \
    systemd \
    sdbusplus \
    phosphor-logging \
    boost \
    i2c-tools \
    cli11 \
    nlohmann-json \
    gtest \
    phosphor-dbus-interfaces \
    udev \
    "
FILES:${PN} += "${systemd_system_unitdir}/xyz.openbmc_project.mctpd@.service"
FILES:${PN} += "/usr/share/mctp/mctp_config.json"
