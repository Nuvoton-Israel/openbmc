DESCRIPTION = "U-boot for Nuvoton NPCM7xx Baseboard Management Controller"

require recipes-bsp/u-boot/u-boot.inc

PROVIDES += "u-boot"

DEPENDS += "dtc-native"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=a2c678cfd4a4d97135585cad908541c6"

S = "${WORKDIR}/git"

UBRANCH = "npcm7xx"
SRC_URI = "git://github.com/Nuvoton-Israel/u-boot.git;branch=${UBRANCH}"
SRC_URI += " file://seperate_dtb.patch"
SRCREV = "196461383f7d043f18cab3bb34dded89fba4712a"

PV .= "+${UBRANCH}+"

do_deploy_append (){
	do_deploy_dtb
}