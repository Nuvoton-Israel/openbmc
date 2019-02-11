SUMMARY = "Phosphor OpenBMC IPMI daemon"
DESCRIPTION = "Phosphor OpenBMC IPMI router and plugin libraries"
PR = "r1"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-support-messaging-cmd.patch"

