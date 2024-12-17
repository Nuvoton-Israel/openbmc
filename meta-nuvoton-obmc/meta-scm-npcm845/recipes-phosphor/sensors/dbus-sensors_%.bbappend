FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI:append = " file://0001-add-NIC-temp-sensor.patch"
#SRC_URI:append = " file://0002-increase-adc-max-reading.patch"
#SRC_URI:append = " file://0003-change-PSU-sensor-name-to-meet-customer-requirement.patch"
#SRC_URI:append = " file://0004-add-dimm-sensor.patch"
#SRC_URI:append = " file://0005-add-psu-sesnor-p2011-and-mx16550.patch"
#SRC_URI:append = " file://xyz.openbmc_project.dimmsensor.service"
    
PACKAGECONFIG = "\
    hwmontempsensor \
    fansensor \
    psusensor \
    adcsensor \
    intrusionsensor \
    nvmesensor \
    mcutempsensor \
	intelcpusensor \
    "

#PACKAGECONFIG[dimmsensor] = "-Ddimm=enabled, -Ddimm=disabled"
#SYSTEMD_SERVICE:${PN}:append = "${@bb.utils.contains('PACKAGECONFIG', 'dimmsensor', \
#                                              ' xyz.openbmc_project.dimmsensor.service', \
#                                               '', d)}"

#do_install:append() {
#    install -d ${D}${systemd_system_unitdir}
#    install -m 0644 ${UNPACKDIR}/xyz.openbmc_project.dimmsensor.service \
#        ${D}${systemd_system_unitdir}
#}
