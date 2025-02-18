FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append =" file://evb-npcm750.cfg"
SRC_URI:append =" file://0001-dts-arm-nuvoton-npcm750-evb-add-openbmc-partition-su.patch"
