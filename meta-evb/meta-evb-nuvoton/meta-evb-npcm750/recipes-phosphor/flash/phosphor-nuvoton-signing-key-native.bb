SUMMARY = "Nuvoton private key for signing images"
DESCRIPTION = "Use this key to sign nuvoton's images."
PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${PHOSPHORBASE}/COPYING.apache-2.0;md5=34400b68072d710fecd0a2940a0d1658"

inherit allarch
inherit native

SRC_URI += "file://Nuvoton.priv"

do_install() {
	bbplain "Using Nuvoton image signing key!"
	install -d ${D}${datadir}
	install -m 400 ${WORKDIR}/Nuvoton.priv ${D}${datadir}
}
