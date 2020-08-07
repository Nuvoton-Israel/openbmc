FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI_append_buv-runbmc = " \
    file://0001-add-Unit-property-in-Value-interface.patch \
    file://0002-add-Scale-d-bus-interface-property.patch \
    file://0003-Avoid-power-state-always-ADC-cannot-trigger-alarm.patch \
    file://0004-wait-mapper-for-avoid-failed-to-find-log.patch \
    "
