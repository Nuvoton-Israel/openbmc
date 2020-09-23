SRC_URI = "git://github.com/Nuvoton-Israel/phosphor-bmc-code-mgmt.git"
SRCREV = "0c9804dfc8a0632afcbcbcbaa83a1a80c6c961a8"

FILES_${PN}-updater_append_olympus-nuvoton = " \
    ${datadir}/phosphor-bmc-code-mgmt/bios-release \
    ${datadir}/phosphor-bmc-code-mgmt/mcu-release"

PACKAGECONFIG_olympus-nuvoton += "verify_signature"
