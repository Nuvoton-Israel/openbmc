SUMMARY = "Phosphor OpenBMC IPMI daemon"
DESCRIPTION = "Phosphor OpenBMC IPMI router and plugin libraries"
PR = "r1"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRCREV = "1e12112baf56f9a8ec6dbf7fb409c84f35fff1e8"
SRC_URI += "file://0001-rmq.patch"
SRC_URI += "file://0002-sel-add-reading.patch"
SRC_URI += "file://xyz.openbmc_project.Control.Host.conf"

do_install_append() {
        install -d ${D}${dbus_system_confdir}
        install -m 0644 ${WORKDIR}/xyz.openbmc_project.Control.Host.conf \
                ${D}${dbus_system_confdir}
}
