FILESEXTRAPATHS_prepend_buv-runbmc := "${THISDIR}/${PN}:"

inherit obmc-phosphor-systemd
PACKAGECONFIG = "7seg"

SERVICE_FILE_7SEG = "postcode-7seg.service"

do_install_append_buv-runbmc() {
     rm ${D}${systemd_unitdir}/system/postcode-7seg@.service
}
