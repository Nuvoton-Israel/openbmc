FILESEXTRAPATHS:append:evb-npcm845 := "${THISDIR}/${PN}:"
RMCPP_IFACE = "eth0"
SRC_URI:append:evb-npcm845 = " file://0001-Add-RemoteIPAddr-support.patch"
