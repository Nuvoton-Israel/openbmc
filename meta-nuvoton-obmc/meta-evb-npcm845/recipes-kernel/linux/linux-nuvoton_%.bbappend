FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://evb-npcm845.cfg"
SRC_URI:append = " file://af_mctp.cfg"
