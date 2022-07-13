FILESEXTRAPATHS:append:scm-npcm845 := "${THISDIR}/${PN}:"
SRC_URI:append:scm-npcm845 = " file://0001-Revert-Remove-HMAC-SHA1-from-Authentication-Integrit.patch"
SRC_URI:append:scm-npcm845 = " file://0001-Add-RemoteIPAddr-support.patch"

RMCPP_IFACE = "eth0"
