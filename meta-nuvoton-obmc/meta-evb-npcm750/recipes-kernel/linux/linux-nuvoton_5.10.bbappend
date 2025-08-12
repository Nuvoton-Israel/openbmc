FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append =" file://evb-npcm750.cfg"
SRC_URI:append =" file://0001-partitions.patch"
SRC_URI:append =" file://enable-configfs-hid.cfg"
SRC_URI:append =" file://enable-configfs-mstg.cfg"
SRC_URI:append =" file://enable-jtag-master.cfg"
SRC_URI:append =" file://enable-slave-mqueue.cfg"
SRC_URI:append =" file://enable-v4l2-kvm.cfg"
