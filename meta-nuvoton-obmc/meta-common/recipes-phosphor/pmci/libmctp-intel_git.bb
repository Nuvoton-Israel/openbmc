SUMMARY = "libmctp:intel"
DESCRIPTION = "Implementation of MCTP(DMTF DSP0236)"

SRC_URI = "git://git@github.com/Nuvoton-Israel/libmctp.git;protocol=ssh;branch=master"
SRCREV = "a3c7da738b08145c9c204fe2ce531ba6ffb41157"

S = "${UNPACKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0 | GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0d30807bb7a4f16d36e96b78f9ed8fae"

inherit cmake

DEPENDS += "i2c-tools"
TARGET_CFLAGS += "-DMCTP_HAVE_FILEIO"
TARGET_CFLAGS += "-DMCTP_DEFAULT_ALLOC"
