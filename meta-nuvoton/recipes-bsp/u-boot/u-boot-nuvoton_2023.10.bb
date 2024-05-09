DESCRIPTION = "U-boot for Nuvoton NPCM7xx/NPCM8xx Baseboard Management Controller"

require u-boot-common-nuvoton_${PV}.inc
require u-boot-nuvoton.inc
require u-boot-emmc.inc

PROVIDES += "u-boot"

DEPENDS += "bc-native dtc-native"

SRC_URI:append:df-phosphor-mmc = " file://u-boot-emmc.cfg"
UBOOT_ENV_SIZE = "0x40000"
UBOOT_ENV_SUFFIX = "bin"
