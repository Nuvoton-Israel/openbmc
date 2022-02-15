EXTRA_OEMESON:append:evb-npcm845 = " -Derror_info_cap=256"
FILESEXTRAPATHS:append:evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm845 = " file://0001-Fix-wrong-type-of-TRANSACTION_ID-metadata.patch"

