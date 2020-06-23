FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRCREV = "2cdc49585235a6557c9cbb6c8b75c064fc02681a"
SRC_URI_append_olympus-nuvoton = " file://0001-olympus-kcsbridged.patch"
SRC_URI_append_olympus-nuvoton = " file://99-ipmi-kcs.rules.rules"

KCS_DEVICE = "ipmi_kcs1"

do_install_append_olympus-nuvoton() {
    install -d ${D}/lib/udev/rules.d
    install -m 0644 ${WORKDIR}/99-ipmi-kcs.rules.rules ${D}/lib/udev/rules.d
}
