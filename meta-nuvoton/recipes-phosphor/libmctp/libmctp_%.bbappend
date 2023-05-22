#SRCREV = "45d1332818c13df182242a8cb80cbe9f983fd057"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-add-npcmi3c-binding.patch"
SRC_URI += "file://0002-libmctp-add-smbus-binding.patch"

DEPENDS += "i2c-tools"

