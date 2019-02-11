FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

#SRCREV = "af6227a3eb3fc918425d7588e001a75bd348232d"
SRC_URI += "file://0001-add-sensor-log.patch"

NAMES = " \
        i2c-bus@82000/tmp100@48 \
        i2c-bus@81000/lm75@48 \
        "
ITEMSFMT = "ahb/apb/{0}.conf"

ITEMS += "${@compose_list(d, 'ITEMSFMT', 'NAMES')}"

ENVS = "obmc/hwmon/{0}"
SYSTEMD_ENVIRONMENT_FILE_${PN} += "${@compose_list(d, 'ENVS', 'ITEMS')}"

# Fan sensors
FITEMS = "pwm-fan-controller@103000.conf"
FENVS = "obmc/hwmon/ahb/apb/{0}"
SYSTEMD_ENVIRONMENT_FILE_${PN} += "${@compose_list(d, 'FENVS', 'FITEMS')}"
