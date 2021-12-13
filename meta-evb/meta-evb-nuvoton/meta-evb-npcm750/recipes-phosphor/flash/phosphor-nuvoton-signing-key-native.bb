SUMMARY = "Nuvoton private key for signing images"
DESCRIPTION = "Use this key to sign nuvoton's images."
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch
inherit native

SRC_URI += "file://Nuvoton.priv"

do_install() {
	bbplain "Using Nuvoton image signing key!"
	install -d ${D}${datadir}
	install -m 400 ${WORKDIR}/Nuvoton.priv ${D}${datadir}
}
