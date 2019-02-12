SUMMARY = "Phosphor OpenBMC IPMI daemon"
DESCRIPTION = "Phosphor OpenBMC IPMI router and plugin libraries"
PR = "r1"

FILESEXTRAPATHS_append := "${THISDIR}/${PN}:"

SRCREV = "3342a8e0876909b34c076172727b8cac861f5277"
SRC_URI += "file://0001-support-messaging-cmd.patch"
SRC_URI += "file://0002-convert-sel-entry.patch"

