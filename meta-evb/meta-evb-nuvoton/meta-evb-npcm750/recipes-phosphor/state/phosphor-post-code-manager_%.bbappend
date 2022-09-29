FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://0001-delay-serialize.patch"
