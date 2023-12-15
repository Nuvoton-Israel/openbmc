FILESEXTRAPATHS:prepend :=  "${THISDIR}/file:"

SRC_URI:append = " file://BootBlockAndHeader_RunBMC.xml"
SRC_URI:append = " file://UbootHeader_RunBMC.xml"
SRC_URI:append = " file://poleg_key_map.xml"
SRC_URI:append = " file://poleg_fuse_map.xml"
SRC_URI:append = " file://0001-Adjust-paths-for-use-OTP-with-Bitbake.patch"

do_install:append() {
	install -d ${DEST}
	install -m 0644 ${WORKDIR}/BootBlockAndHeader_RunBMC.xml ${DEST}/BootBlockAndHeader_${IGPS_MACHINE}.xml
	install -m 0644 ${WORKDIR}/UbootHeader_RunBMC.xml ${DEST}/UbootHeader_${IGPS_MACHINE}.xml 
	install -m 0644 ${WORKDIR}/poleg_key_map.xml ${DEST}/
	install -m 0644 ${WORKDIR}/poleg_fuse_map.xml ${DEST}/
	install -m 0644 ImageGeneration/inputs/mergedFuses.xml ${DEST}/
	install -m 0644 ImageGeneration/inputs/mergedSecureBoot.xml ${DEST}/
	install -d ${DEPLOY_DIR_IMAGE}/inputs
	install -m 0644 ImageGeneration/inputs/*.bin ${DEPLOY_DIR_IMAGE}/inputs/
}
