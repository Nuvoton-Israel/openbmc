FILESEXTRAPATHS_prepend_olympus-nuvoton := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/Nuvoton-Israel/phosphor-bmc-code-mgmt.git"
SRCREV = "b368beed067996c18bbee6e4fe8683f401fa157b"

SRC_URI_append_olympus-nuvoton = " file://mcu-release"

FILES_${PN}-updater_append_olympus-nuvoton = " \
    ${datadir}/phosphor-bmc-code-mgmt/bios-release \
    ${datadir}/phosphor-bmc-code-mgmt/mcu-release"

PACKAGECONFIG_olympus-nuvoton += "verify_signature"

do_install_append_olympus-nuvoton() {
    install -d ${D}${datadir}/phosphor-bmc-code-mgmt/
    install -m 0777 ${WORKDIR}/mcu-release ${D}${datadir}/phosphor-bmc-code-mgmt/
}
