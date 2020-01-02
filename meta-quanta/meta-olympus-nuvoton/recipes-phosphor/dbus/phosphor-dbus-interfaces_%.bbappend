FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI_append_olympus-nuvoton = " file://0001-Add-sensor-threshold-error-items.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-set-watchdog-Interval-value-to-three-minutes.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-add-error-WatchdogTimedOut-under-Control.Boot.patch"
