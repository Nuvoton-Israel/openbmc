FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-phosphor-multi-gpio-monitor-add-low-pulse-detection.patch"
SRC_URI:append = " file://GpioMonitorConfig.json"
SRC_URI:append = " file://phosphor-multi-gpio-monitor.service"

FILES:${PN}-monitor:append = " ${datadir}/phosphor-gpio-monitor/GpioMonitorConfig.json"

do_install:append() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    install -m 0644 ${UNPACKDIR}/GpioMonitorConfig.json \
        ${D}${datadir}/phosphor-gpio-monitor/GpioMonitorConfig.json
    install -m 0644 ${UNPACKDIR}/phosphor-multi-gpio-monitor.service \
        ${D}${systemd_system_unitdir}/phosphor-multi-gpio-monitor.service
}
