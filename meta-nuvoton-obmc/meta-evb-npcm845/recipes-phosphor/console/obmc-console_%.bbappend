FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://80-evb-npcm845-sol.rules"


# Remove what installed by common recipe
OBMC_CONSOLE_HOST_TTY = ""
SYSTEMD_SUBSTITUTIONS:remove = "OBMC_CONSOLE_HOST_TTY:${OBMC_CONSOLE_HOST_TTY}:${PN}-ssh@.service"
SYSTEMD_SUBSTITUTIONS:remove = "OBMC_CONSOLE_HOST_TTY:${OBMC_CONSOLE_HOST_TTY}:${PN}-ssh.socket"

# Declare port spcific conf and service files
HOST_CONSOLE_TTY = "ttyS1 ttyS4 ttyS5"
# OBMF serial channels (ssh ports 2230/2231)
HOST_CONSOLE_TTY:append:df-obmf = " ttyOBMF0_0 ttyOBMF0_1"
CONSOLE_CONF_FMT = "file://server.{0}.conf"
SRC_URI:append = " ${@compose_list(d, 'CONSOLE_CONF_FMT', 'HOST_CONSOLE_TTY')}"
CONSOLE_SSH_SOCKET_FILE_FMT = "file://${PN}-{0}-ssh.socket"
CONSOLE_SSH_SERVICE_FILE_FMT = "file://${PN}-{0}-ssh@.service"
SRC_URI:append = " ${@compose_list(d, 'CONSOLE_SSH_SOCKET_FILE_FMT', 'HOST_CONSOLE_TTY')}"
SRC_URI:append = " ${@compose_list(d, 'CONSOLE_SSH_SERVICE_FILE_FMT', 'HOST_CONSOLE_TTY')}"

CONSOLE_SSH_SOCKET_FMT = "${PN}-{0}-ssh.socket"
CONSOLE_SSH_SERVICE_FMT = "${PN}-{0}-ssh@.service"

SYSTEMD_SERVICE:${PN} = " \
    ${PN}@.service \
    ${@compose_list(d, 'CONSOLE_SSH_SOCKET_FMT', 'HOST_CONSOLE_TTY')} \
    ${@compose_list(d, 'CONSOLE_SSH_SERVICE_FMT', 'HOST_CONSOLE_TTY')} \
    "

do_install:append() {
    for i in ${HOST_CONSOLE_TTY}
    do
        install -m 0644 ${UNPACKDIR}/server.${i}.conf ${D}${sysconfdir}/${BPN}/server.${i}.conf
        install -m 0644 ${UNPACKDIR}/${BPN}-${i}-ssh.socket ${D}${systemd_unitdir}/system/${BPN}-${i}-ssh.socket
        install -m 0644 ${UNPACKDIR}/${BPN}-${i}-ssh@.service ${D}${systemd_unitdir}/system/${BPN}-${i}-ssh@.service
    done

    # Deal with files installed by the base package's .bb install function
    rm -f ${D}${sysconfdir}/${BPN}.conf
    rm -f ${D}${sysconfdir}/${BPN}/server..conf
    rm -rf ${D}${systemd_unitdir}/system/${BPN}-ssh@.service.d/
    rm -f ${D}${systemd_unitdir}/system/${BPN}-ssh@.service
    rm -f ${D}${systemd_unitdir}/system/${BPN}-ssh.socket
    # Overwrite base package's obmc-console@.service with our own
    #install -m 0644 ${WORKDIR}/${BPN}@.service ${D}${systemd_unitdir}/system/${BPN}@.service

    # handle Nuvoton rules
    rm -f ${D}/${nonarch_base_libdir}/udev/rules.d/80-obmc-console-uart.rules
    install -D -m 0644 ${UNPACKDIR}/80-evb-npcm845-sol.rules ${D}/${nonarch_base_libdir}/udev/rules.d
}

# OBMF ttys come and go with SMC1: start the server from udev and stop it
# with the tty, instead of restarting it until it hits the start limit.
SRC_URI:append:df-obmf = " file://81-obmf-console.rules"
do_install:append:df-obmf() {
    install -m 0644 ${UNPACKDIR}/81-obmf-console.rules ${D}/${nonarch_base_libdir}/udev/rules.d
    for i in ${HOST_CONSOLE_TTY}
    do
        case $i in ttyOBMF*) ;; *) continue ;; esac
        d=${D}${systemd_unitdir}/system/${BPN}@${i}.service.d
        install -d $d
        printf "[Unit]\nBindsTo=dev-%s.device\nAfter=dev-%s.device\n" $i $i > $d/obmf-tty.conf
    done
}
