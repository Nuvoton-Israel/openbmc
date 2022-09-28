FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://80-evb-npcm750-sol.rules"
OBMC_CONSOLE_HOST_TTY:evb-npcm750 = "ttyS1"

do_install:append:evb-npcm750() {
        install -d ${D}/lib/udev/rules.d
        rm -f ${D}/lib/udev/rules.d/80-obmc-console-uart.rules
        install -m 0644 ${WORKDIR}/80-evb-npcm750-sol.rules ${D}/lib/udev/rules.d
}
