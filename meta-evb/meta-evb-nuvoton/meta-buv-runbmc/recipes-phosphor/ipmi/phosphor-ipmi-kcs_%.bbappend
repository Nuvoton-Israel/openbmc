FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://99-ipmi-kcs.rules.rules"

KCS_DEVICE:buv-runbmc = "ipmi_kcs1"

do_install:append:buv-runbmc() {
        install -d ${D}/lib/udev/rules.d
        install -m 0644 ${WORKDIR}/99-ipmi-kcs.rules.rules ${D}/lib/udev/rules.d
}
