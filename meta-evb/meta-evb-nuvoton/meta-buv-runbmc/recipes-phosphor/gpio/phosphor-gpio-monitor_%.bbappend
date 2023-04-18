FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}-monitor += "phosphor-multi-gpio-monitor.service"
SYSTEMD_SERVICE:${PN}-monitor += "psusensor_reload.service"
SYSTEMD_SERVICE:${PN}-monitor += "psu_hwmon_start.service"
SYSTEMD_SERVICE:${PN}-monitor += "psu_hwmon_stop.service"

SRC_URI:append:buv-runbmc = " file://BUV-GpioMonitorConfig-EM.json"
SRC_URI:append:buv-runbmc = " file://psu_hotplug_action.sh"
SRC_URI:append:buv-runbmc = " file://BUV-GpioMonitorConfig-IM.json"
SRC_URI:append:buv-runbmc = " file://0001-phosphor-gpio-monitor-add-set-Inventory.Item-Present.patch"

RDEPENDS:${PN} += "bash"

FILES:${PN}:append = " ${datadir}/phosphor-gpio-monitor/"

do_install:append:buv-runbmc() {
    install -d ${D}${datadir}/phosphor-gpio-monitor
    rm -f ${D}${datadir}/phosphor-gpio-monitor/*.json
    if [ "${DISTRO}" = "buv-entity" ];then
        install -m 0644 -D ${WORKDIR}/BUV-GpioMonitorConfig-EM.json \
            ${D}${datadir}/phosphor-gpio-monitor/BUV-GpioMonitorConfig.json
    else
        install -m 0644 -D ${WORKDIR}/BUV-GpioMonitorConfig-IM.json \
            ${D}${datadir}/phosphor-gpio-monitor/BUV-GpioMonitorConfig.json
    fi

    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/psu_hotplug_action.sh ${D}${bindir}/
}
