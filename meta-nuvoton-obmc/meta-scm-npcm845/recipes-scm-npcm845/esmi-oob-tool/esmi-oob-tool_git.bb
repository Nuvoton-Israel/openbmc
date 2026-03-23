SUMMARY = "AMD EPYC System Management Interface Library"
DESCRIPTION = "AMD EPYC System Management Interface Library for user space APML implementation"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://License.txt;md5=a53f186511a093774907861d15f7014c"

FILESEXTRAPATHS:prepend := "${THISDIR}:"


RDEPENDS:${PN}:append = "bash i2c-tools i3c-tools"

SRC_URI = "git://github.com/amd/esmi_oob_library;protocol=https;branch=master"
SRC_URI:append = " file://0001-fixed-header-incude.patch"
SRCREV = "00cc0fb0265af1d240a0aff5ed96f90a73ff8c51"


inherit cmake

do_install:append() {
        install -d ${D}${includedir}
        install -m 0644 ${S}/include/esmi_oob/* ${D}${includedir}/
}
