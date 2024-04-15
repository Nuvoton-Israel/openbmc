FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton-515:${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://evb-npcm845.cfg"
SRC_URI:append = " file://enable-v4l2.cfg"
SRC_URI:append = " file://luks.cfg"

SRC_URI:append = " file://0001-dts-nuvoton-evb-npcm845-support-openbmc-partition.patch"
