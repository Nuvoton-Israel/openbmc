FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:olympus-nuvoton = " file://olympus-nuvoton.cfg"
SRC_URI:append:olympus-nuvoton = " file://vlan.cfg"
SRC_URI:append:olympus-nuvoton = " file://0002-add-tps53622-and-tps53659.patch"
SRC_URI:append:olympus-nuvoton = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
SRC_URI:append:olympus-nuvoton = " file://enable-v4l2.cfg"
SRC_URI:append:olympus-nuvoton = " file://0001-drivers-misc-porting-mcu-flash-driver.patch"
SRC_URI:append:olympus-nuvoton = " file://0001-drivers-spi-Bugfixed-npcm_fiu_uma_read-set-wrong-val.patch"