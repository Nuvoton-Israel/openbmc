FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " \
    file://0001-hwmon-temp-add-tmp100-support.patch \
    file://0002-Fansensor-get-pwm-from-other-hwmon-path.patch \
    file://0003-psu-sensor-add-fan3-support.patch \
    file://0004-psu-sensor-support-p2011-psu.patch \
    file://0005-add-NIC-temp-sensor.patch \
    file://0006-increase-adc-max-reading.patch \
    file://0007-change-psu-sensor-name.patch \
    file://0008-add-sesnor-max16550.patch \
    file://0009-add-dimm-sensor.patch \
    file://0010-hwmon-temp-add-lm75-support.patch \
    file://xyz.openbmc_project.dimmsensor.service \
    "

PACKAGECONFIG:evb-npcm750 = "\
    hwmontempsensor \
    fansensor \
    psusensor \
    adcsensor \
    intrusionsensor \
    nvmesensor \
    dimmsensor \
    mcutempsensor \
    "

PACKAGECONFIG[dimmsensor] = "-Ddimm=enabled, -Ddimm=disabled"
SYSTEMD_SERVICE:${PN}:append:evb-npcm750 = "${@bb.utils.contains('PACKAGECONFIG', 'dimmsensor', \
                                               ' xyz.openbmc_project.dimmsensor.service', \
                                               '', d)}"

SYSTEMD_SERVICE:${PN} += "xyz.openbmc_project.nvmesensor.service"

do_install:append:evb-npcm750() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.dimmsensor.service \
        ${D}${systemd_system_unitdir}
}
