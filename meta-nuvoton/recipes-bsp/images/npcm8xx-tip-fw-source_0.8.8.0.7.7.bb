require npcm8xx-tip-fw-source.inc

# npcm8xx-tip-fw-manifest pins npcm8xx-tip to 'master', but that branch is a
# squashed open-sourcing snapshot that carries an older L1 version and no
# LICENSE file. The 0.8.8/0.7.7 release lives on main_nuvoton, tagged
# TIP_FW_0.8.8_L0_0.7.7_L1, which is what the pre-built npcm8xx-tip-fw
# recipe of the same version ships.
SRCREV_cerberus = "40a94de257ba4af49074fd2562b3eec9818d2f69"
SRCREV_tip = "a2ac271f3ff47249e533836cc2aa63b1545d01b0"
SRCREV_mbedtls = "5e146adef63b326b04282252639bebc2730939c6"
