FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append = " file://olympus-nuvoton.cfg"
SRC_URI:append = " file://enable-vcd-ece.cfg"
SRC_URI:append = " file://vlan.cfg"
SRC_URI:append = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
SRC_URI:append = " file://0001-dts-arm-nuvoton-runbmc-olympus-update-flash0-partiti.patch"
