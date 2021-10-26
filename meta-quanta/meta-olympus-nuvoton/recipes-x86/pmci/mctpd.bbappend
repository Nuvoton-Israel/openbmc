FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/${PN}:"

SMBUS_BINDING = "pcie"

SRC_URI:olympus-nuvoton = "git://github.com/Nuvoton-Israel/pmci.git;protocol=ssh"

SRCREV:olympus-nuvoton = "6fe3d2677320c391aed5c6d61af38ed43b508e62"

SRC_URI:append:olympus-nuvoton = " file://mctp_config.json"

do_install:append:olympus-nuvoton() {
    install -m 0644 -D ${WORKDIR}/mctp_config.json \
        ${D}${datadir}/mctp/mctp_config.json
}
