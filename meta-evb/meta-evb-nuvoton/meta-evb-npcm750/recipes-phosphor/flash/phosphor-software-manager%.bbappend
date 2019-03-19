FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PACKAGECONFIG ??= "verify_signature"

SRC_URI += "file://Support_Multiple_Update_Package.patch"

