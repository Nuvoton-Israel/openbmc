KBRANCH = "Poleg-4.19.16-OpenBMC"
LINUX_VERSION = "4.19.16"

KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=git;branch=${KBRANCH}"
SRCREV = "c06b76b16e378ef2945e3475a0897871abf14d7f"

FILESEXTRAPATHS_prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI += "file://runbmc-nuvoton.cfg"
SRC_URI += "file://0001-runbmc-dts.patch"
SRC_URI += "file://0001-Revert-mtd-spi-nor-fix-options-for-mx66l51235f.patch"
SRC_URI += "file://0001-add-tps53622-and-tps53659.patch"
SRC_URI += "file://runbmc-nuvoton-enable-slave-mqueue.cfg"
