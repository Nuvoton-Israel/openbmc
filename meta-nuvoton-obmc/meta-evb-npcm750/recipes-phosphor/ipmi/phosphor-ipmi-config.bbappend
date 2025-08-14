FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit image_version

SRC_URI:append = " file://channel_config.json"
SRC_URI:append = " file://dev_id.json"

do_install:append() {
    install -m 0644 -D ${UNPACKDIR}/channel_config.json \
        ${D}${datadir}/ipmi-providers/channel_config.json
    install -m 0644 -D ${UNPACKDIR}/dev_id.json \
        ${D}${datadir}/ipmi-providers/dev_id.json
}
