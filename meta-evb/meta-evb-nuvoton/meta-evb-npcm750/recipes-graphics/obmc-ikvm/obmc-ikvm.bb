SUMMARY = "OpenBMC VNC server and IKVM daemon"
DESCRIPTION = "obmc-ikvm is a vncserver for nuvoton npcm750"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d32239bcb673463ab874e80d47fae504"

DEPENDS = "libvncserver"
RDEPENDS_${PN} = "libvncserver"

inherit obmc-phosphor-systemd

SRC_URI = "git://github.com/Nuvoton-Israel/obmc-ikvm"
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 obmc-ikvm ${D}${bindir}
}

SYSTEMD_SERVICE_${PN} = "obmc-ikvm.service"
TARGET_CC_ARCH += "${LDFLAGS}"
