FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

#SRCREV = "06b4df97b7f271154abb1d28716cb3a782a27e96"
SRC_URI += "file://0001-sensor-add-property.patch"
SRC_URI += "file://0001-Set-Watchdog-ExpireAction-as-None.patch"
