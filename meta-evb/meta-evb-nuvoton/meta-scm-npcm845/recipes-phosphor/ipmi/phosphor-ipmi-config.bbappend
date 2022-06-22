FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit image_version

SRC_URI:append:scm-npcm845 = " file://channel_config.json"
SRC_URI:append:scm-npcm845 = " file://dev_id.json"
SRC_URI:append:scm-npcm845 = " file://fw.json"

FILES:${PN}:append:scm-npcm845 = " ${datadir}/ipmi-providers/fw.json"

do_install:append:scm-npcm845() {
    install -m 0644 -D ${WORKDIR}/channel_config.json \
        ${D}${datadir}/ipmi-providers/channel_config.json
    install -m 0644 -D ${WORKDIR}/dev_id.json \
        ${D}${datadir}/ipmi-providers/dev_id.json
    install -m 0644 -D ${WORKDIR}/fw.json \
        ${D}${datadir}/ipmi-providers/fw.json
}
