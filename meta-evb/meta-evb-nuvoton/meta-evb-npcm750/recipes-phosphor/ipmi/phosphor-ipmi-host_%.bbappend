SUMMARY = "Phosphor OpenBMC IPMI daemon"
DESCRIPTION = "Phosphor OpenBMC IPMI router and plugin libraries"
PR = "r1"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRCREV = "2c2af2ca713f56b117ad2c8c1a1f0e370b7c2d9c"
SRC_URI += "file://0001-support-messaging-cmd.patch"
SRC_URI += "file://0002-convert-sel-entry.patch"

