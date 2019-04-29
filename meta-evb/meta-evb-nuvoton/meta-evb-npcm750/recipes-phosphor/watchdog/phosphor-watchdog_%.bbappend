FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRCREV = "26eef26c97beec18d0f96fd1cd792229caded542"

SRC_URI += "file://0001-disable-watchdog-when-host-boot-successfully.patch"
