FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://0001-hwmon-temp-add-lm75-support.patch"

PACKAGECONFIG = "\
    hwmontempsensor \
    fansensor \
    adcsensor \
    "
