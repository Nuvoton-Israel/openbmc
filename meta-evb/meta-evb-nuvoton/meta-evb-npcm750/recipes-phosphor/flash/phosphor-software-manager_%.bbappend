FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/Nuvoton-Israel/phosphor-bmc-code-mgmt.git"
SRCREV = "19836fc0fc40901b187aa7e15b4d2e2e3bb9e411"


FILES_${PN}-updater_append_evb-npcm750 = " \
    ${datadir}/phosphor-bmc-code-mgmt/bios-release"

PACKAGECONFIG_evb-npcm750 += "verify_signature"
