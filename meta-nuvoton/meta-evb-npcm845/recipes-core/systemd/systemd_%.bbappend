FILESEXTRAPATHS:prepend:evb-npcm845 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm845 = " file://85-persistent-net.rules"

do_install:append:evb-npcm845() {
	install -m 0644 ${WORKDIR}/85-persistent-net.rules ${D}${sysconfdir}/udev/rules.d/
}
