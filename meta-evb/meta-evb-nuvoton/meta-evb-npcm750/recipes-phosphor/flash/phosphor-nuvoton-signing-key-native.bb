SUMMARY = "Nuvoton private key for signing images"
DESCRIPTION = "Use this key to sign nuvoton's images."
PR = "r1"

inherit allarch
inherit native
inherit obmc-phosphor-license

SRC_URI += "file://Nuvoton.priv"

do_install() {
	bbplain "Using Nuvoton image signing key!"
	install -d ${D}${datadir}
	install -m 400 ${WORKDIR}/Nuvoton.priv ${D}${datadir}
}
