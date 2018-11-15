FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://obmc-update-verify.sh"

do_install_append() {
	install -m 0755 ${WORKDIR}/obmc-update-verify.sh ${D}/update
}

FILES_${PN} += " /update"
