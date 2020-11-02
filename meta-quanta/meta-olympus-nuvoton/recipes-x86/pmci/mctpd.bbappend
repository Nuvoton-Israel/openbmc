FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"
#FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

#SMBUS_BINDING = "smbus"

SRC_URI_olympus-nuvoton = "git://github.com/Nuvoton-Israel/pmci.git;protocol=ssh"

SRCREV_olympus-nuvoton = "448498b926276521e2f82050e55790b6fd842c19"

SRC_URI_append_olympus-nuvoton = " file://mctp_config.json"

do_install_append_olympus-nuvoton() {
    install -m 0644 -D ${WORKDIR}/mctp_config.json \
        ${D}${datadir}/mctp/mctp_config.json
}
