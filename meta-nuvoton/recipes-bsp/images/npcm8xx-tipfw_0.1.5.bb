LICENSE = "CLOSED"

SRC_URI = " \
    file://arbel_tip_fw.${PV}.bin \
    file://Kmt_TipFw.bin \
"

S = "${WORKDIR}"

inherit deploy

do_deploy () {
	install -D -m 644 ${S}/arbel_tip_fw.${PV}.bin ${DEPLOYDIR}/arbel_tip_fw.bin
    install -D -m 644 ${S}/Kmt_TipFw.bin ${DEPLOYDIR}/Kmt_TipFw.bin
}

addtask deploy before do_build after do_compile
