SUMMARY = "Nuvoton private key for signing images"
DESCRIPTION = "Use this key to sign nuvoton's images."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
PR = "r1"

SRC_URI += "file://Nuvoton.key"
SRC_URI += "file://Nuvoton.crt"

inherit allarch
inherit native

do_install() {
	bbplain "Using Nuvoton image signing key!"

	install -d ${DEPLOY_DIR_IMAGE}/uboot_fitkey
	install -m 400 ${WORKDIR}/Nuvoton.key ${DEPLOY_DIR_IMAGE}/uboot_fitkey/
	install -m 400 ${WORKDIR}/Nuvoton.crt ${DEPLOY_DIR_IMAGE}/uboot_fitkey/	
}
