SUMMARY = "libmctp:intel"
DESCRIPTION = "Implementation of MCTP(DMTF DSP0236)"

SRC_URI = "git://git@github.com/intel-bmc/firmware.bmc.openbmc.libraries.libmctp.git;protocol=ssh;branch=main"
SRCREV = "4f964c09542f560aa1a34fa436e17b5c03699999"

S = "${WORKDIR}/git"

PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0 | GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0d30807bb7a4f16d36e96b78f9ed8fae"

inherit cmake

DEPENDS += "i2c-tools"
