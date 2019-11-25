FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-main-Fix-BMC-system-stuck-when-doing-enumerate-state.patch"

SNOOP_DEVICE = "npcm7xx-lpc-bpc0"
