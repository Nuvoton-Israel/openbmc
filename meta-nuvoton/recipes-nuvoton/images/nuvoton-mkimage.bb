DESCRIPTION = "Generate Boot image for npcm SOC"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'tee', 'optee-os', '', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'tee', 'arm-trusted-firmware', '', d)} \
"

inherit deploy
BOOT_STAGING  = "${S}/${SOC_FAMILY}"

do_compile () {
    cp ${DEPLOY_DIR_IMAGE}/tee.bin   ${BOOT_STAGING}
    cp ${DEPLOY_DIR_IMAGE}/bl31.bin  ${BOOT_STAGING}
    # run bingo stuff
}

do_compile[depends] += " \
    arm-trusted-firmware:do_deploy \
    optee-os:do_deploy \
"

# install file to image
do_install () {
    install -d ${D}/boot
}

# copy boot image to deploy folder
do_deploy () {

}

FILES_${PN} = "/boot"
#addtask deploy before do_build after do_compile
