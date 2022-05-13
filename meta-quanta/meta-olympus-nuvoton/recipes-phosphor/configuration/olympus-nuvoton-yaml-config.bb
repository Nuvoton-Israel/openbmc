SUMMARY = "YAML configuration for Olympus Nuvoton"
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch

SRC_URI:olympus-nuvoton = " \
    file://olympus-nuvoton-ipmi-fru.yaml \
    file://olympus-nuvoton-ipmi-fru-properties.yaml \
    file://olympus-nuvoton-ipmi-sensors.yaml \
    file://olympus-nuvoton-dbus-monitor-config.yaml \
    file://olympus-nuvoton-ipmi-inventory-sensors.yaml \
    "

S = "${WORKDIR}"

do_install:olympus-nuvoton() {
    install -m 0644 -D olympus-nuvoton-ipmi-fru-properties.yaml \
        ${D}${datadir}/${BPN}/ipmi-extra-properties.yaml
    install -m 0644 -D olympus-nuvoton-ipmi-fru.yaml \
        ${D}${datadir}/${BPN}/ipmi-fru-read.yaml
    install -m 0644 -D olympus-nuvoton-ipmi-sensors.yaml \
        ${D}${datadir}/${BPN}/ipmi-sensors.yaml
    install -m 0644 -D olympus-nuvoton-ipmi-inventory-sensors.yaml \
        ${D}${datadir}/${BPN}/ipmi-inventory-sensors.yaml
    install -m 0644 -D olympus-nuvoton-dbus-monitor-config.yaml \
        ${D}${datadir}/phosphor-dbus-monitor/dbus-monitor-config.yaml
}

FILES:${PN}-dev = " \
    ${datadir}/${BPN}/ipmi-extra-properties.yaml \
    ${datadir}/${BPN}/ipmi-fru-read.yaml \
    ${datadir}/${BPN}/ipmi-sensors.yaml \
    ${datadir}/${BPN}/ipmi-inventory-sensors.yaml \
    ${datadir}/phosphor-dbus-monitor/dbus-monitor-config.yaml \
    "

ALLOW_EMPTY:${PN} = "1"
