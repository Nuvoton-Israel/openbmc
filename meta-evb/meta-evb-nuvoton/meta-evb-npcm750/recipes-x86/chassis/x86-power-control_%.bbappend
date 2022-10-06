FILESEXTRAPATHS:prepend:evb-npcm750 := "${THISDIR}/${PN}:"

SRC_URI:append:evb-npcm750 = " file://power-config-host0.json"
SRC_URI:append:evb-npcm750 = " file://0001-skip-POWER-BUTTON.patch"
SRC_URI:append:evb-npcm750 = " file://0002-support-chassis-on-off-and-post-complete-target.patch"
SRC_URI:append:evb-npcm750  = " file://obmc-chassis-poweroff.target"
SRC_URI:append:evb-npcm750  = " file://obmc-chassis-poweron.target"
SRC_URI:append:evb-npcm750  = " file://obmc-post-complete.target"

FILES:${PN} += " ${datadir}/x86-power-control/power-config-host0.json \"

SYSTEMD_SERVICE:${PN}:append:evb-npcm750 = " obmc-chassis-poweroff.target"
SYSTEMD_SERVICE:${PN}:append:evb-npcm750  = " obmc-chassis-poweron.target"
SYSTEMD_SERVICE:${PN}:append:evb-npcm750  = " obmc-post-complete.target"

inherit obmc-phosphor-systemd

do_install:append:evb-npcm750() {
    install -d ${D}${datadir}/x86-power-control
    install -m 0644 -D ${WORKDIR}/power-config-host0.json \
        ${D}${datadir}/x86-power-control/power-config-host0.json
}
