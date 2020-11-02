SUMMARY = "PLDM Lib"
DESCRIPTION = "Implementation of PLDM (DTMF DSP)"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

SRC_URI = "git://github.com/Intel-BMC/pmci.git;protocol=ssh"
SRCREV = "a8e84b6f61639ab85b0e2368c9ec755e692aa14c"

S = "${WORKDIR}/git/libpldm_intel/"

PV = "1.0+git${SRCPV}"

inherit cmake

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += " \
    gtest \
    "