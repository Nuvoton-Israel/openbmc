SUMMARY = "Sets BMC_BOOT_DONE on boot complete"
DESCRIPTION ="Indicate BMC boot complete with BMC_BOOT_DONE (S)GPIO"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://bmc-boot-done.sh \
	   file://bmc_boot_done.service \
	  "

inherit systemd

DEPENDS += "systemd"
RDEPENDS:${PN} += "bash"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/bmc-boot-done.sh ${D}${bindir}/

        install -d ${D}${systemd_system_unitdir}
        install -m 0644 ${WORKDIR}/bmc_boot_done.service ${D}${systemd_system_unitdir}
}

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "bmc_boot_done.service"
