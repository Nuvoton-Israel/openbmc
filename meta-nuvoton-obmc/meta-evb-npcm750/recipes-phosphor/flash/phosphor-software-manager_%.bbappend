FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG:append  = " verify_signature flash_bios"
EXTRA_OEMESON:append = " -Doptional-images=image-bios"
