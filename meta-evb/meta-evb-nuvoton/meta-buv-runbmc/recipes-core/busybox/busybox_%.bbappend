FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"
SRC_URI_append_buv-runbmc = " file://busybox.cfg"
SRC_URI_append_buv-runbmc = "${@bb.utils.contains('DISTRO_FEATURES', 'buv-dev', ' file://buv-dev.cfg', '', d)}"
