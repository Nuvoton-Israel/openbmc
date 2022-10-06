FILESEXTRAPATHS:append:evb-npcm750 := "${THISDIR}/${PN}:"
SRC_URI:append:evb-npcm750 = " file://0001-Revert-Remove-HMAC-SHA1-from-Authentication-Integrit.patch"
SRC_URI:append:evb-npcm750 = " file://0001-Add-RemoteIPAddr-support.patch"
SRC_URI:append:evb-npcm750 = " file://0002-add-server-type-and-oem-id-to-meet-MS-spec.patch"
SRC_URI:append:evb-npcm750 = " file://0003-set-channel-security-keys.patch"

RMCPP_IFACE = "eth2"
