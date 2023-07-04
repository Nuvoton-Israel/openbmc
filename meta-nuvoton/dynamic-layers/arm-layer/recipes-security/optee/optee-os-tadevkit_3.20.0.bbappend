SRC_URI:remove:npcm8xx = "git://github.com/OP-TEE/optee_os.git;branch=master;protocol=https"

SRC_URI:remove:npcm8xx = "file://0003-core-link-add-no-warn-rwx-segments.patch"
SRC_URI:remove:npcm8xx = "file://0004-core-Define-section-attributes-for-clang.patch"
SRC_URI:remove:npcm8xx = "file://0005-core-arm-S-EL1-SPMC-boot-ABI-update.patch"
SRC_URI:remove:npcm8xx = "file://0006-core-ffa-add-TOS_FW_CONFIG-handling.patch"
SRC_URI:remove:npcm8xx = "file://0007-core-spmc-handle-non-secure-interrupts.patch"
SRC_URI:remove:npcm8xx = "file://0008-core-spmc-configure-SP-s-NS-interrupt-action-based-o.patch"

SRC_URI:append:npcm8xx = "git://github.com/Nuvoton-Israel/optee_os.git;branch=npcm_3_21;protocol=https"

SRCREV:npcm8xx = "606609bd8780a786210c17135cfa7a42a6aed79e"
