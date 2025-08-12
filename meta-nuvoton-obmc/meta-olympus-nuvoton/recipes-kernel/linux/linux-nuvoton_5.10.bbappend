FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://olympus-nuvoton.cfg"
SRC_URI:append = " file://vlan.cfg"
SRC_URI:append = " file://enable-v4l2-kvm.cfg"

SRC_URI:append = " file://0002-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"
SRC_URI:append = " file://0002-add-tps53622-and-tps53659.patch"
SRC_URI:append = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
