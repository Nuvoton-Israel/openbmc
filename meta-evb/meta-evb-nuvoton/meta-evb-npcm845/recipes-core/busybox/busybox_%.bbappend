FILESEXTRAPATHS_prepend_evb-npcm845 := "${THISDIR}/${PN}:"
SRC_URI_append_evb-npcm845 = " file://busybox.cfg"
SRC_URI_append_evb-npcm845 = "${@bb.utils.contains('DISTRO_FEATURES', 'buv-dev', ' file://buv-dev.cfg', '', d)}"
