DESCRIPTION = "Network Block Device"
HOMEPAGE = "http://nbd.sourceforge.net"
SECTION = "net"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "glib-2.0 gnutls "

SRC_URI = "http://downloads.sourceforge.net/project/${BPN}/${BPN}/${PV}/${BPN}-${PV}.tar.xz"
#16
#SRC_URI[md5sum] = "7950a7c2b496a4c78101c7131ecd0781"
#SRC_URI[sha256sum] = "263bc261e1b884601c968fd7009989608b13fd2d7a2142da69f5f8dd50d42fe6"

#17
#SRC_URI[md5sum] = "98b74c655ed94a66686c5ba19480d98e"
#SRC_URI[sha256sum] = "d95c6bb1a3ab33b953af99b73fb4833e123bd25433513b32d57dbeb1a0a0d189"

#SRC_URI = "${SOURCEFORGE_MIRROR}/${BPN}/${BPN}-${PV}.tar.xz"
SRC_URI[md5sum] = "8527f2039f2873ac3d033fc4a6a8d632"
SRC_URI[sha256sum] = "27392c4e1de910c62fb2608a56f54e1c834b48219663dab2063ca27cba4c368e"

inherit autotools pkgconfig 

PACKAGES = "${PN}-client ${PN}-server ${PN}-dbg ${PN}-trdump ${PN}-doc"

FILES_${PN}-client = "${sbindir}/${BPN}-client"
FILES_${PN}-server = "${bindir}/${BPN}-server"
FILES_${PN}-trdump = "${bindir}/${BPN}-trdump"
