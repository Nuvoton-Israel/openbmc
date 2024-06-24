FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://aurea-scm.json"
SRC_URI:append = " file://aurea-hpm.json"
SRC_URI:append:scm-npcm845 = " file://blacklist.json"
SRC_URI:append:m1120-c2195 = " file://blacklist-m1120.json"

do_install:append() {
    rm -f ${D}/usr/share/entity-manager/configurations/*.json
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${WORKDIR}/aurea-scm.json \
        ${D}${datadir}/entity-manager/configurations/aurea-scm.json
    install -m 0644 -D ${WORKDIR}/aurea-hpm.json \
        ${D}${datadir}/entity-manager/configurations/aurea-hpm.json
}

do_install:append:scm-npcm845() {
    install -m 0644 -D ${WORKDIR}/blacklist.json\
        ${D}${datadir}/entity-manager/blacklist.json
}

do_install:append:m1120-c2195() {
    install -m 0644 ${WORKDIR}/blacklist-m1120.json \
        ${D}${datadir}/entity-manager/blacklist.json
}
