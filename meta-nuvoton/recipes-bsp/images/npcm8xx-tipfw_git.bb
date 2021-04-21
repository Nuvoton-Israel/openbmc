LICENSE = "CLOSED"

SRC_URI = " \
    file://arbel_tip_fw.bin \
"

S = "${WORKDIR}"

inherit deploy

do_deploy () {
	install -D -m 644 ${S}/arbel_tip_fw.bin ${DEPLOYDIR}/arbel_tip_fw.bin
}

addtask deploy before do_build after do_compile
