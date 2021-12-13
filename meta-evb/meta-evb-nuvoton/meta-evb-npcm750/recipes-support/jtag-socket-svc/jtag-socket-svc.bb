DESCRIPTION = "Jtag socket server"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://COPYING \
	   	file://Makefile \
		file://src/handlers/debug_enable.c \
		file://src/handlers/power_debug.c \
		file://src/handlers/prdy.c \
		file://src/handlers/SoftwareJTAGHandler.c \
		file://src/handlers/tck_mux_select.c \
		file://src/handlers/platform_reset.c \
		file://src/handlers/power_good.c \
		file://src/handlers/preq.c \
		file://src/handlers/target_handler.c \
		file://src/handlers/xdp_present.c \
		file://src/logging.c \
		file://src/socket_main.c \
		file://include/asd_common.h \
		file://include/gpio.h \
		file://include/logging.h \
		file://include/power_debug.h \
		file://include/prdy.h \
		file://include/SoftwareJTAGHandler.h \
		file://include/tck_mux_select.h \
		file://include/debug_enable.h \
		file://include/jtag_drv.h \
		file://include/platform_reset.h \
		file://include/power_good.h \
		file://include/preq.h \
		file://include/target_handler.h \
		file://include/xdp_present.h \
	  "
S = "${WORKDIR}"

do_compile() {
	make
}

do_install() {
        install -d ${D}${bindir}
        install -m 0755 jtag_socket_svc ${D}${bindir}
}
