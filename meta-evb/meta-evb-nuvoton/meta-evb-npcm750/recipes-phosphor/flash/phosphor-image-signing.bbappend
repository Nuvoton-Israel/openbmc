FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://Nuvoton.key"
SRC_URI += "file://Nuvoton.crt"

SIGNING_KEY = "${STAGING_DIR_NATIVE}${datadir}/Nuvoton.key"
DEPENDS += "phosphor-nuvoton-signing-key-native"

