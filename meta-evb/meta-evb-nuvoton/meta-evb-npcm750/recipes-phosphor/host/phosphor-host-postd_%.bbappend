FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-support-npcm7xx-lpc-bpc0-and-snooper.patch"

SNOOP_DEVICE = "npcm7xx-lpc-bpc0"
