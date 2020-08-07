FILESEXTRAPATHS_append_buv-runbmc := "${THISDIR}/${PN}:"

DEPENDS_append_buv-runbmc = " phosphor-dbus-interfaces"

SRC_URI_append_buv-runbmc = " file://0001-add-event-log-support.patch"

# Enable threshold monitoring
EXTRA_OECMAKE_append_buv-runbmc = " -DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON \
    -DREDFISH_LOG_MONITOR_EVENTS_LOG=ON \
"

