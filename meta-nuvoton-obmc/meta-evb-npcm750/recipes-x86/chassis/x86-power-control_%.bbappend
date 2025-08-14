FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://power-config-host0.json"

FILES:${PN}:append = " ${datadir}/x86-power-control/power-config-host0.json"

do_install:append() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 -D ${UNPACKDIR}/power-config-host0.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}
