FILESEXTRAPATHS_prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI += "file://evb-npcm750.cfg"
SRC_URI += "file://enable-vcd-ece.cfg"
SRC_URI += "file://enable-configfs-hid.cfg"
SRC_URI += "file://enable-configfs-mstg.cfg"
SRC_URI += "file://enable-jtag-master.cfg"
SRC_URI += "file://enable-slave-mqueue.cfg"

SRC_URI += "file://0001-partitions.patch"
SRC_URI += "file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI += "file://0001-fru-modify-dts-for-eeprom.patch"
#SRC_URI += "file://0001-hand-over-pspi1-control-to-jtag-master.patch"
