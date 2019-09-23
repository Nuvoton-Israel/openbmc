SRC_URI_remove = "git://github.com/openbmc/phosphor-ipmi-flash"
SRC_URI_append = " git://github.com/Nuvoton-Israel/phosphor-ipmi-flash"

SRCREV = "${AUTOREV}"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

PACKAGECONFIG_nuvoton += " static-bmc reboot-update"

NUVOTON_FLASH_PCIVGA  = "0x7F400000"
NUVOTON_FLASH_PCIMBOX = "0xF0848000"
NUVOTON_FLASH_LPC     = "0xc0008000"

#EXTRA_OECONF_append = " --enable-nuvoton-lpc"
#EXTRA_OECONF_append = " --enable-nuvoton-p2a-mbox"
EXTRA_OECONF_append = " --enable-nuvoton-p2a-vga"

IPMI_FLASH_BMC_ADDRESS_nuvoton = "${NUVOTON_FLASH_PCIVGA}"

EXTRA_OECMAKE_append = " -DCMAKE_BUILD_TYPE:type=Debug"

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

