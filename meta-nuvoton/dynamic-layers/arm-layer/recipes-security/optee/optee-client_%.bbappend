FILESEXTRAPATHS:append:npcm8xx := "${THISDIR}/${PN}:"

SYSTEMD_SERVICE:${PN}:npcm8xx = "tee-supplicant@0.service"
FILES:${PN}:append:npcm8xx = " ${systemd_system_unitdir}/tee-supplicant@.service"

EXTRA_OECMAKE:append:npcm8xx = " \
    -DCFG_TEE_FS_PARENT_PATH='/var/tee' \
    -DRPMB_EMU=OFF \
    "
