FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://ipmb-channels.json"
FILES:${PN}:append:buv-runbmc = " ${datadir}/ipmbbridge/ipmb-channels.json"

do_install:append:buv-runbmc() {
    install -d ${D}${datadir}/ipmbbridge
    install -m 0644 -D ${WORKDIR}/ipmb-channels.json \
        ${D}${datadir}/ipmbbridge/ipmb-channels.json
}

