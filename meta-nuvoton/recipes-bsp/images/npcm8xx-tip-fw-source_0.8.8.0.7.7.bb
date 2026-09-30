require npcm8xx-tip-fw-source.inc

# npcm8xx-tip-fw-manifest pins npcm8xx-tip to 'master', but that branch is a
# squashed open-sourcing snapshot that carries an older L1 version and no
# LICENSE file. The 0.8.8/0.7.7 release lives on main_nuvoton, tagged
# TIP_FW_0.8.8_L0_0.7.7_L1, which is what the pre-built npcm8xx-tip-fw
# recipe of the same version ships. Later main_nuvoton commits only add
# build fixes on top of that tag, the firmware version is unchanged.
SRCREV_cerberus = "40a94de257ba4af49074fd2562b3eec9818d2f69"
SRCREV_tip = "f018d8e7d373cfe9bbc38164c534e3d074d51815"
SRCREV_mbedtls = "5e146adef63b326b04282252639bebc2730939c6"
