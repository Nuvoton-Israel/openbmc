# Add libgpiod and libnpcm-jtag dependencies
DEPENDS:append = " libgpiod libnpcm-jtag"

SRCREV_openocd = "91bd4313444c5a949ce49d88ab487608df7d6c37"
# Add patches and source files for NPCM JTAG adapter
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://0001-add-npcm-jtag-adapter.patch \
    file://0002-add-npcm-jtag-configure-option.patch \
    file://0003-svf-suuport-loop-command.patch \
"

# Enable NPCM JTAG and linuxgpiod adapter
PACKAGECONFIG[linuxgpiod] = "--enable-linuxgpiod,--disable-linuxgpiod"
PACKAGECONFIG[npcm-jtag] = "--enable-npcm-jtag,--disable-npcm-jtag"
PACKAGECONFIG:append = " linuxgpiod npcm-jtag"

