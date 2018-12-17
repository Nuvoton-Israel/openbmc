DESCRIPTION = "Jtag socket server"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=12f884d2ae1ff87c09e5b7ccc2c4ca7e"

SRC_URI = "file://COPYING \
	   file://Makefile \
	   file://src/* \
	   file://include/* \
	  "

S = "${WORKDIR}"

do_compile() {
	make
}

do_install() {
        install -d ${D}${bindir}
        install -m 0755 jtag_socket_svc ${D}${bindir}
}
