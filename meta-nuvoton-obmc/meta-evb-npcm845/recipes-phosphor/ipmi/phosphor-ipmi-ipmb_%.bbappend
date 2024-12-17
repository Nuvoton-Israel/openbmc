FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://ipmb-channels.json"
FILES:${PN}:append = " ${datadir}/ipmbbridge/ipmb-channels.json"

do_install:append() {
    install -d ${D}${datadir}/ipmbbridge
    install -m 0644 -D ${UNPACKDIR}/ipmb-channels.json \
        ${D}${datadir}/ipmbbridge/ipmb-channels.json
}

