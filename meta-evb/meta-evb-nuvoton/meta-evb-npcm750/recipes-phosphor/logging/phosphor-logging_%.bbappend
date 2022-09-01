EXTRA_OEMESON:append:evb-npcm750 = " -Derror_info_cap=256"
FILESEXTRAPATHS:append:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://0001-Fix-wrong-type-of-TRANSACTION_ID-metadata.patch"

