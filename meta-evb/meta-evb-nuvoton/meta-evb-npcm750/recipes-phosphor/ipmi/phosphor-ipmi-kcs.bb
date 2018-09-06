SUMMARY = "Phosphor OpenBMC KCS to DBUS"
DESCRIPTION = "Phosphor OpenBMC KCS to DBUS."
PR = "r1"

inherit autotools pkgconfig
inherit obmc-phosphor-license
inherit obmc-phosphor-dbus-service

DBUS_SERVICE_${PN} = "xyz.openbmc_project.Ipmi.Channel.Sms.service"

DEPENDS += " \
        autoconf-archive-native \
        systemd \
        sdbusplus \
        "
RDEPENDS_${PN} += " \
        libsystemd \
        "

S = "${WORKDIR}"
SRC_URI += " \
        file://bootstrap.sh \
        file://configure.ac \
        file://kcsbridged.cpp \
        file://Makefile.am \
        file://xyz.openbmc_project.Ipmi.Channel.Sms.conf \
        file://README.md \
        "

# This is how linux-libc-headers says to include custom uapi headers
CXXFLAGS_append = " -I ${STAGING_KERNEL_DIR}/include/uapi"
do_configure[depends] += "virtual/kernel:do_shared_workdir"
