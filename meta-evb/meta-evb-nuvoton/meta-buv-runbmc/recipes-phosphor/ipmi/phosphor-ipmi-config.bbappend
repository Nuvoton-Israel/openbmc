FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit image_version

SRC_URI:append:buv-runbmc = " file://channel_config.json"
SRC_URI:append:buv-runbmc = " file://dev_id.json"

do_install:append:buv-runbmc() {
    install -m 0644 -D ${WORKDIR}/channel_config.json \
        ${D}${datadir}/ipmi-providers/channel_config.json
    install -m 0644 -D ${WORKDIR}/dev_id.json \
        ${D}${datadir}/ipmi-providers/dev_id.json
}
