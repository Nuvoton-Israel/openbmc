KBRANCH ?= "Poleg-5.4-OpenBMC"
LINUX_VERSION ?= "5.4.80"

SRCREV="541c3ee2a24954a99b9e769da7e6e56ea148f59a"

require linux-nuvoton.inc

SRC_URI_append_nuvoton = " file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI_append_nuvoton = " file://0002-add-tps53622-and-tps53659.patch"
SRC_URI_append_nuvoton = " file://0003-i2c-nuvoton-npcm750-runbmc-integrate-the-slave-mqueu.patch"
SRC_URI_append_nuvoton = " file://0004-driver-ncsi-replace-del-timer-sync.patch"
SRC_URI_append_nuvoton = " file://0008-WAR-skip-clear-fault-for-flexpower.patch"
SRC_URI_append_nuvoton = " file://0010-driver-misc-npcm7xx-mcu-flash-add-NPCM-MCU-driver.patch"
SRC_URI_append_nuvoton = " file://0011-driver-misc-npcm7xx-mcu-flash-fix-mcu-reset-signal-a.patch"
SRC_URI_append_nuvoton = " file://0012-driver-misc-npcm7xx-mcu-flash-add-npcm7xx_mcu_releas.patch"
SRC_URI_append_nuvoton = " file://0015-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"
SRC_URI_append_nuvoton = " file://0018-dts-runbmc-olympus-add-power-reset-button-and-post-c.patch"
SRC_URI_append_nuvoton = " file://0019-dts-runbmc-olympus-add-ext1-reset-type-to-wd1-for-wa.patch"

#SRC_URI_append_nuvoton = " file://v4l2.cfg"
#SRC_URI_append_nuvoton = " file://0001-driver-video-nuvoton-add-video-driver.patch"
