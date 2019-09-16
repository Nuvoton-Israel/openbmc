SRC_URI_remove = "git://github.com/openbmc/phosphor-ipmi-flash"
SRC_URI_append = " git://github.com/Nuvoton-Israel/phosphor-ipmi-flash"

SRCREV = "${AUTOREV}"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
EXTRA_OECONF_append = " --enable-static-layout"
EXTRA_OECONF_append = " --enable-reboot-update"
EXTRA_OECONF_append = " STATIC_HANDLER_STAGED_NAME=/run/initramfs/image-bmc"

EXTRA_OECONF_append = " --enable-lpc-bridge"
EXTRA_OECONF_append = " --enable-nuvoton-lpc"
EXTRA_OECONF_append = " MAPPED_ADDRESS=0xc0008000"

#EXTRA_OECONF_append = " --enable-pci-bridge"

#EXTRA_OECONF_append = " --enable-nuvoton-p2a-mbox"
#EXTRA_OECONF_append = " MAPPED_ADDRESS=0xF0848000"

#EXTRA_OECONF_append = " --enable-nuvoton-p2a-vga"
#EXTRA_OECONF_append = " MAPPED_ADDRESS=0x7F400000"

SRC_URI += "file://bmc-verify.sh"
SRC_URI += "file://phosphor-ipmi-flash-bmc-verify.service"

do_install_append() {
	install -d ${D}/usr/sbin
	install -m 0755 -D ${WORKDIR}/bmc-verify.sh ${D}/${sbindir}/bmc-verify.sh

	install -d ${D}${systemd_unitdir}/system/
	install -m 0644 ${WORKDIR}/phosphor-ipmi-flash-bmc-verify.service ${D}${systemd_unitdir}/system/
}

SYSTEMD_SERVICE_${PN}_append = " phosphor-ipmi-flash-bmc-verify.service"

pkg_postinst_${PN}() {
	LINK="$D$systemd_system_unitdir/phosphor-ipmi-flash-bmc-verify.wants/phosphor-ipmi-flash-bmc-verify.service"
	TARGET="../phosphor-ipmi-flash-bmc-verify.service"
	mkdir -p $D$systemd_system_unitdir/phosphor-ipmi-flash-bmc-verify.wants
	ln -s $TARGET $LINK
}

pkg_prerm_${PN}() {
	LINK="$D$systemd_system_unitdir/phosphor-ipmi-flash-bmc-verify.wants/phosphor-ipmi-flash-bmc-verify.service"
	rm $LINK
}

