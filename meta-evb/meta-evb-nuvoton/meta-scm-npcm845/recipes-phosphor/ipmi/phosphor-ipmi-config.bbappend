FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend:m1120-c2195 := "${THISDIR}/${PN}/m1120:"

inherit image_version

SRC_URI:append = " file://channel_config.json"
SRC_URI:append = " file://dev_id.json"
SRC_URI:append = " file://fw.json"
SRC_URI:append = " file://system_guid.json"
SRC_URI:append = " file://power_reading.json"

FILES:${PN}:append = " ${datadir}/ipmi-providers/fw.json"
FILES:${PN}:append = " ${datadir}/ipmi-providers/system_guid.json"

do_install:append() {
    install -m 0644 -D ${WORKDIR}/channel_config.json \
        ${D}${datadir}/ipmi-providers/channel_config.json
    install -m 0644 -D ${WORKDIR}/dev_id.json \
        ${D}${datadir}/ipmi-providers/dev_id.json
    install -m 0644 -D ${WORKDIR}/fw.json \
        ${D}${datadir}/ipmi-providers/fw.json
    install -m 0644 -D ${WORKDIR}/system_guid.json \
        ${D}${datadir}/ipmi-providers/system_guid.json
    install -m 0644 -D ${WORKDIR}/power_reading.json \
        ${D}${datadir}/ipmi-providers/power_reading.json
}
