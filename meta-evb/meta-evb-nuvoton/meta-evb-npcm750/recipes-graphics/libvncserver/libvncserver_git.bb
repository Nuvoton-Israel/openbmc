DESCRIPTION = "libvncserver - A library implementing the VCN protocol"
HOMEPAGE = "https://github.com/LibVNC/libvncserver"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=361b6b837cad26c6900a926b62aada5f"
DEPENDS += "zlib jpeg libpng openssl"
BRANCH = "master"
SRC_URI = "git://github.com/LibVNC/libvncserver;branch=${BRANCH};"
SRCREV = "8415ff4c3517c6697d53e1a17bba35284f480891"
S = "${WORKDIR}/git"

inherit autotools binconfig pkgconfig

EXTRA_OECONF += "--without-gcrypt --without-gnutls"
