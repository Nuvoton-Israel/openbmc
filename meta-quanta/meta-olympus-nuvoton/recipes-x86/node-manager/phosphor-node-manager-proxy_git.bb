SUMMARY = "Node Manager Proxy"
DESCRIPTION = "The Node Manager Proxy provides a simple interface for communicating \
with Management Engine via IPMB"

SRC_URI = "git://git@github.com/Intel-BMC/node-manager;protocol=ssh"
SRCREV = "de212d839bb515939bd089c66072e4fcf33b8653"
PV = "0.1+git${SRCPV}"

FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"
SRC_URI += "file://0001-add-scale-and-change-the-number-from-uint16-to-int64.patch \
            file://0003-watch-for-propery-change-of-PowerCap.patch \
            file://0004-add-force-recovery-functions.patch \
            file://0002-fixed-sensors-name.patch \
            file://0005-remove-fno-rtti-cxx-flags.patch \
            "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

SYSTEMD_SERVICE_${PN} = "node-manager-proxy.service"

DEPENDS = "sdbusplus \
           phosphor-logging \
           boost"

S = "${WORKDIR}/git"
inherit cmake systemd
