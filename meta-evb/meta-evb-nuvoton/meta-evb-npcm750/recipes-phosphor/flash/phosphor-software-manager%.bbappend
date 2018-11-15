FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PACKAGECONFIG ??= "verify_signature"

SRC_URI += "file://Update_bmcimage_list.patch"

