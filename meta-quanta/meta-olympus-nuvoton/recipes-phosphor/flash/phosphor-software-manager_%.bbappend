SRC_URI = "git://github.com/Nuvoton-Israel/phosphor-bmc-code-mgmt.git"
SRCREV = "4c50791cd016081c7f69d79a6c2dc6eaea416a94"

FILES_${PN}-updater_append_olympus-nuvoton = " \
    ${datadir}/phosphor-bmc-code-mgmt/bios-release \
    ${datadir}/phosphor-bmc-code-mgmt/mcu-release"

PACKAGECONFIG_olympus-nuvoton += "verify_signature"
