SUMMARY = "Nuvoton OpenBMC console daemon"
DESCRIPTION = "Nuvoton Daemon to handle UART console connections"
HOMEPAGE = "http://github.com/openbmc/obmc-console"
PR = "r1"

inherit obmc-phosphor-license

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

OBMC_CONSOLE_HOST_TTY := "ttyS1"

do_build_append() {
        install -m 0644 ${THISDIR}/files/${PN}.conf ${WORKDIR}/${PN}.conf
}
