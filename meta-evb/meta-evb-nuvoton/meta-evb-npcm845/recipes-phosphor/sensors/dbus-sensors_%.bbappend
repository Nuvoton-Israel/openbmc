FILESEXTRAPATHS_prepend_evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI_append_evb-npcm845 = " \
    file://0001-hwmon-temp-add-tmp100-support.patch \
    file://0002-Add-thermal-zone-support-in-hwmon-sensor.patch \
    "
