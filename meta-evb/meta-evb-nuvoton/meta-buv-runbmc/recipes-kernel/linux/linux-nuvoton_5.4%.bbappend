FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/linux-nuvoton-54:${THISDIR}/linux-nuvoton:"

SRC_URI:append:buv-runbmc = " \
  file://buv-runbmc.cfg \
  file://nuvoton-npcm750-buv-runbmc.dts;subdir=git/arch/${ARCH}/boot/dts \
  "
SRC_URI:append:buv-runbmc = " file://enable-v4l2.cfg"
