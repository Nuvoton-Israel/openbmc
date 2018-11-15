FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://Nuvoton.priv"

SIGNING_KEY = "${STAGING_DIR_NATIVE}${datadir}/Nuvoton.priv"
DEPENDS += "phosphor-nuvoton-signing-key-native"

