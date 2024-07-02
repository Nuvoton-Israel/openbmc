FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}-monitor:append = " phosphor-multi-gpio-monitor.service"
SYSTEMD_SERVICE:${PN}-monitor:append = " dp_hotplug.service"

SRC_URI:append = " file://dp_hotplug.sh"
SRC_URI:append:scm-npcm845 = " file://GpioMonitorConfig.json"
SRC_URI:append:m1120-c2195 = " file://GpioMonitorConfig-m1120.json"

RDEPENDS:${PN} += "bash"

FILES:${PN}:append = " ${datadir}/phosphor-gpio-monitor/"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/dp_hotplug.sh ${D}${bindir}/
}

do_install:append:scm-npcm845() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    rm -f ${D}${datadir}/phosphor-gpio-monitor/*.json
    install -m 0644 -D ${WORKDIR}/GpioMonitorConfig.json \
            ${D}${datadir}/phosphor-gpio-monitor/GpioMonitorConfig.json
}

do_install:append:m1120-c2195() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    rm -f ${D}${datadir}/phosphor-gpio-monitor/*.json
    install -m 0644 -D ${WORKDIR}/GpioMonitorConfig-m1120.json \
            ${D}${datadir}/phosphor-gpio-monitor/GpioMonitorConfig.json
}
