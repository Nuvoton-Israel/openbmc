FILESEXTRAPATHS_prepend_evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI_append_evb-npcm845 += " \
    file://0001-networkd-create-new-socket.patch \
    file://0001-network-Fix-crash-while-dhcp4-address-gets-update.patch \
"
