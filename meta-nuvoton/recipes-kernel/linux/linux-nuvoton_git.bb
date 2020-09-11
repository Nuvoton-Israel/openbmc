KBRANCH ?= "Poleg-5.4-OpenBMC"
LINUX_VERSION ?= "5.4.16"

SRCREV="463d09287f242100822691006586fe9b9d5ade05"

require linux-nuvoton.inc

SRC_URI_append_nuvoton = " file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI_append_nuvoton = " file://0002-add-tps53622-and-tps53659.patch"
SRC_URI_append_nuvoton = " file://0003-i2c-nuvoton-npcm750-runbmc-integrate-the-slave-mqueu.patch"
SRC_URI_append_nuvoton = " file://0004-driver-ncsi-replace-del-timer-sync.patch"
SRC_URI_append_nuvoton = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
SRC_URI_append_nuvoton = " file://0010-driver-misc-npcm7xx-mcu-flash-add-NPCM-MCU-driver.patch"
SRC_URI_append_nuvoton = " file://0011-driver-misc-npcm7xx-mcu-flash-fix-mcu-reset-signal-a.patch"
