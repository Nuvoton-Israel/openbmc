FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/Nuvoton-Israel/phosphor-bmc-code-mgmt.git"
SRCREV = "ecb9e8b2581ebd256a21514e0ada8ef501735b04"

SRC_URI += "file://0001-fixed-build-break.patch"

FILES_${PN}-updater_append_buv-runbmc = " \
    ${datadir}/phosphor-bmc-code-mgmt/bios-release"

PACKAGECONFIG_buv-runbmc += "verify_signature"
