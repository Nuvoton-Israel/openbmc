FILESEXTRAPATHS:prepend:npcm8xx:= "${THISDIR}/${PN}:"

SRC_URI:append:npcm8xx= " file://0001-fansensor-add-Nuvoton-npcm845-fan-support.patch"
