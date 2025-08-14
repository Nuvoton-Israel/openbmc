FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://NUVOTON-POLEG-EVB.json"
SRC_URI:append = " file://baseboard.fru.bin"
SRC_URI:append = " file://blacklist.json"

do_install:append() {
    rm -f ${D}/usr/share/entity-manager/configurations/*.json
    install -d ${D}${datadir}/entity-manager
    install -m 0644 -D ${UNPACKDIR}/NUVOTON-POLEG-EVB.json \
        ${D}${datadir}/entity-manager/configurations/NUVOTON-POLEG-EVB.json
    install -m 0644 -D ${UNPACKDIR}/blacklist.json\
        ${D}${datadir}/entity-manager/blacklist.json
    mkdir -p ${D}/etc/fru
    install -m 0444 ${UNPACKDIR}/baseboard.fru.bin ${D}/etc/fru
}
