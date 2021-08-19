FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " phosphor-dbus-interfaces"
#SRC_URI_append_olympus-nuvoton = " file://0001-add-event-log-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-watchdog-event-Add-support-for-timeout-watchdog-even.patch"

EXTRA_OECMAKE_append_olympus-nuvoton= " -DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"
EXTRA_OECMAKE_append_olympus-nuvoton= " -DSEL_LOGGER_MONITOR_THRESHOLD_ALARM_EVENTS=ON"
EXTRA_OECMAKE_append_olympus-nuvoton= " -DSEL_LOGGER_MONITOR_WATCHDOG_EVENTS=ON"
EXTRA_OECMAKE_append_olympus-nuvoton= " -DREDFISH_LOG_MONITOR_PULSE_EVENTS=ON"
EXTRA_OECMAKE_append_olympus-nuvoton= " -DREDFISH_LOG_MONITOR_EVENTS_LOG=ON"
