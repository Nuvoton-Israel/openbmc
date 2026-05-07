FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI:append = " file://0001-pldm-pldmtool-add-netid-parameter-support.patch"
SRC_URI:append = " file://0001-add-MCTPUSBDevice.patch"
SRC_URI:append = " file://0001-fixed-InvalidArgs-Erro.patch"
SRC_URI:append = " file://0001-platform-mc-Add-state-sensor-support-as-per-DSP0248.patch"
SRC_URI:append = " file://0001-platform-mc-add-support-for-fan_pwm.patch"
