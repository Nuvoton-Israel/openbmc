SRC_URI:remove:m1120-c2195 = "git://github.com/OP-TEE/optee_os.git;branch=master;protocol=https"
SRC_URI:append:m1120-c2195 = " git://github.com/Nuvoton-Israel/optee_os.git;branch=npcm_3_22;protocol=https"

# We should set rev to 97d41fb, but fTPM function will not work if we move
# to the commit, so revert it and wait for fix.
# SRCREV:m1120-c2195 = "97d41fbeccbd66e94c0bcf06781be86e1c8ffd96"
SRCREV:m1120-c2195 = "1a9f528034c5cc05631f0f85c1cb0db738e44070"

# enable debug log
# EXTRA_OEMAKE:append:evb-npcm845 = " CFG_TEE_CORE_DEBUG=y CFG_TEE_CORE_LOG_LEVEL=3"
