FILESEXTRAPATHS:append:scm-npcm845 := "${THISDIR}/${PN}:"
SRC_URI:append:scm-npcm845 = " file://0001-Revert-Remove-HMAC-SHA1-from-Authentication-Integrit.patch"

RMCPP_IFACE = "eth0"
