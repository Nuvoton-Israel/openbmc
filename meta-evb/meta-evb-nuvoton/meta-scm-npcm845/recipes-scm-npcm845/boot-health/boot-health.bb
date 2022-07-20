PR = "r1"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit obmc-phosphor-systemd
DEPENDS = "systemd"

SRC_URI = "file://scm-boot-health.service"
SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "scm-boot-health.service"

do_install() {
    install -D -m 0644 ${WORKDIR}/scm-boot-health.service \
        ${D}${systemd_unitdir}/system/scm-boot-health.service
}
