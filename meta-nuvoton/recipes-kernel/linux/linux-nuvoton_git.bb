KBRANCH ?= "Poleg-5.4-OpenBMC"
LINUX_VERSION ?= "5.4.16"

SRCREV="aefb0af7dbff8c53e9cbb87fb76682e3d0ceb09b"

require linux-nuvoton.inc

SRC_URI_append_nuvoton = " file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI_append_nuvoton = " file://0002-add-tps53622-and-tps53659.patch"
SRC_URI_append_nuvoton = " file://0003-i2c-nuvoton-npcm750-runbmc-integrate-the-slave-mqueu.patch"
SRC_URI_append_nuvoton = " file://0004-driver-ncsi-replace-del-timer-sync.patch"
SRC_URI_append_nuvoton = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
SRC_URI_append_nuvoton = " file://0010-driver-misc-npcm7xx-mcu-flash-add-NPCM-MCU-driver.patch"
SRC_URI_append_nuvoton = " file://0011-driver-misc-npcm7xx-mcu-flash-fix-mcu-reset-signal-a.patch"
SRC_URI_append_nuvoton = " file://0012-driver-misc-npcm7xx-mcu-flash-add-npcm7xx_mcu_releas.patch"
