FILESEXTRAPATHS_append_olympus-nuvoton := "${THISDIR}/${PN}:"

DEPENDS_append_olympus-nuvoton = " phosphor-dbus-interfaces"

# SRC_URI_append_olympus-nuvoton = " file://0001-add-sensor-evnet-log-support.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-add-event-log-support.patch"

# Enable threshold monitoring
EXTRA_OECMAKE_append = " -DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON \
    -DREDFISH_LOG_MONITOR_EVENTS_LOG=ON \
"

