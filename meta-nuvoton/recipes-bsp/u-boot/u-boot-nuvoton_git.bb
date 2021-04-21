DESCRIPTION = "U-boot for Nuvoton NPCM7xx Baseboard Management Controller"

require u-boot-common-nuvoton.inc
require u-boot-nuvoton.inc

PROVIDES += "u-boot"

DEPENDS += "dtc-native"

FILESEXTRAPATHS_prepend_npcm8xx := "${THISDIR}/${PN}:"
SRC_URI_append_npcm8xx = " file://0001-support-a-larger-FIT-format-image-on-Arbel-EVB.patch "
