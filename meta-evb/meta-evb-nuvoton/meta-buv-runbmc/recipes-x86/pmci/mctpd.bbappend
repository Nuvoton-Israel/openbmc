FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SMBUS_BINDING = "smbus"

SRC_URI:buv-runbmc = "git://github.com/Nuvoton-Israel/pmci.git;protocol=https"

SRCREV:buv-runbmc = "bbbe833676c74b61fdc7bcc67d756eb8f557641a"

SRC_URI:append:buv-runbmc = " file://mctp_config.json"

do_install:append:buv-runbmc() {
    install -m 0644 -D ${WORKDIR}/mctp_config.json \
        ${D}${datadir}/mctp/mctp_config.json
}
