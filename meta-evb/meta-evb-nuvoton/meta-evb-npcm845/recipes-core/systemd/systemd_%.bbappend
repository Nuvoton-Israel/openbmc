FILESEXTRAPATHS:prepend:evb-npcm845:= "${THISDIR}/files:"

SRCREV:evb-npcm845= "4fa9d8f14523982482386d398d2b2669902f2098"

SRC_URI:append:evb-npcm845= " \
    file://0001-networkd-create-new-socket.patch \
"
