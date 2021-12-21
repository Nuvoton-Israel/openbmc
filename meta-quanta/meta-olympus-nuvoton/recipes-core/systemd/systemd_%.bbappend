FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/files:"

SRCREV:olympus-nuvoton = "4fa9d8f14523982482386d398d2b2669902f2098"

SRC_URI:append:olympus-nuvoton = " \
    file://0001-networkd-create-new-socket.patch \
"
