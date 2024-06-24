FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# reload service files
SRC_URI:append = " \
    file://phosphor-ecc.service \
    "

SYSTEMD_SERVICE:${PN}:append = " \
    phosphor-ecc.service \
    "

do_install:append() {
    install -d ${D}${systemd_unitdir}/system/
    install -m 0644 ${WORKDIR}/phosphor-ecc.service \
        ${D}${systemd_unitdir}/system
}
