FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend:m1120-c2195 :="${THISDIR}/${PN}/m1120:"

SRC_URI:append  = " file://scm.json"
SRC_URI:append  = " file://hpm.json"
SRC_URI:append  = " file://blacklist.json"

do_install:append() {
    rm -f ${D}/usr/share/entity-manager/configurations/*.json
    install -d ${D}${datadir}/entity-manager

    install -m 0644 -D ${WORKDIR}/scm.json \
        ${D}${datadir}/entity-manager/configurations/scm.json
    install -m 0644 -D ${WORKDIR}/hpm.json \
        ${D}${datadir}/entity-manager/configurations/hpm.json
    install -m 0644 ${WORKDIR}/blacklist.json \
        ${D}${datadir}/entity-manager/blacklist.json
}
