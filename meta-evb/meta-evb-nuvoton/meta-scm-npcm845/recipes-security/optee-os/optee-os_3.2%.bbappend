SRC_URI:m1120-c2195 = "git://github.com/Nuvoton-Israel/optee_os.git;branch=npcm_3_22;protocol=https"
SRC_URI:m1120-c2195:append = " \
    file://0001-allow-setting-sysroot-for-libgcc-lookup.patch \
    file://0002-core-Define-section-attributes-for-clang.patch \
    file://0003-optee-enable-clang-support.patch \
    file://0004-core-link-add-no-warn-rwx-segments.patch \
"

# We should set rev to 97d41fb, but fTPM function will not work if we move
# to the commit, so revert it and wait for fix.
# SRCREV:m1120-c2195 = "97d41fbeccbd66e94c0bcf06781be86e1c8ffd96"
SRCREV:m1120-c2195 = "1a9f528034c5cc05631f0f85c1cb0db738e44070"
