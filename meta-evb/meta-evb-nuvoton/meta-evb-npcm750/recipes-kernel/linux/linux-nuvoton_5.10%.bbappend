FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:evb-npcm750 = " file://evb-npcm750.cfg"
SRC_URI:append:evb-npcm750 = " file://0001-partitions.patch"
SRC_URI:append:evb-npcm750 = " file://enable-configfs-hid.cfg"
SRC_URI:append:evb-npcm750 = " file://enable-configfs-mstg.cfg"
SRC_URI:append:evb-npcm750 = " file://enable-jtag-master.cfg"
SRC_URI:append:evb-npcm750 = " file://enable-slave-mqueue.cfg"
SRC_URI:append:evb-npcm750 = " file://enable-v4l2.cfg"
