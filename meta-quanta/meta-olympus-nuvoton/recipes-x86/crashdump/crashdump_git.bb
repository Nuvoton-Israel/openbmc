inherit obmc-phosphor-dbus-service
inherit obmc-phosphor-systemd

SUMMARY = "CPU Crashdump"
DESCRIPTION = "CPU utilities for dumping CPU Crashdump and registers over PECI"

DEPENDS = "boost cjson sdbusplus safec gtest libpeci"
inherit cmake

EXTRA_OECMAKE = "-DYOCTO_DEPENDENCIES=ON -DCRASHDUMP_BUILD_UT=OFF"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://LICENSE;md5=43c09494f6b77f344027eea0a1c22830"

SRC_URI = "git://github.com/Intel-BMC/crashdump.git;protocol=https;nobranch=1"
# from now on, bitbake not allow set git revsion without sha-1 style
#SRCREV = "wht-1.0.6"
SRCREV = "edea231cc1df74576e5a46c70bf163bb2b365d99"

S = "${WORKDIR}/git"

SYSTEMD_SERVICE:${PN} += "com.intel.crashdump.service"
DBUS_SERVICE:${PN} += "com.intel.crashdump.service"

# linux-libc-headers guides this way to include custom uapi headers
CFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include/uapi"
CFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include"
CXXFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include/uapi"
CXXFLAGS:append = " -I ${STAGING_KERNEL_DIR}/include"
do_configure[depends] += "virtual/kernel:do_shared_workdir"
