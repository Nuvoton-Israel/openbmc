FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

PACKAGECONFIG:evb-npcm845 += "verify_signature flash_bios"
EXTRA_OEMESON:append:evb-npcm845 = " -Doptional-images=image-bios"
