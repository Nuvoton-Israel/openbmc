FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRCREV = "3a5168723f1a610368a17d1fa5360bf6e04c62c3"
SRC_URI += "file://0001-sensor-add-property.patch"
SRC_URI += "file://0001-Add-power-control-interface.patch"
SRC_URI += "file://0001-Set-Watchdog-ExpireAction-as-None.patch"
