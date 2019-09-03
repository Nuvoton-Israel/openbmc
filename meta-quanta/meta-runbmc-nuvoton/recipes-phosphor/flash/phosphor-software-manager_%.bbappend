FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-updater-Add-initial-bios-version-support.patch"

FILES_${PN}-updater += "${datadir}/phosphor-bmc-code-mgmt/bios-release"

PACKAGECONFIG ??= "verify_signature"
