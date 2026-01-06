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

# Override PACKAGECONFIG to only enable linuxgpiod and npcm-jtag
PACKAGECONFIG = "linuxgpiod npcm-jtag"
PACKAGECONFIG[linuxgpiod] = "--enable-linuxgpiod,--disable-linuxgpiod,libgpiod"
PACKAGECONFIG[npcm-jtag] = "--enable-npcm-jtag,--disable-npcm-jtag,libnpcm-jtag"

# Disable unused features to reduce image size
EXTRA_OECONF:append = " \
	--disable-ftdi --disable-xds110 --disable-usb-blaster --disable-usb-blaster_2 \
	--disable-esp-usb-jtag --disable-jtag-vpi --disable-ft232r --disable-presto \
	--disable-usbprog --disable-openjtag --disable-vsllink --disable-rlink --disable-ulink \
	--disable-armjtagew --disable-buspirate --disable-remote-bitbang --disable-stlink \
	--disable-ti-icdi --disable-osbdm --disable-opendous --disable-sysfsgpio \
	--disable-cmsis-dap --disable-cmsis-dap-v2 \
	--disable-dummy --disable-parport --disable-gw16012 \
	--disable-bcm2835gpio --disable-imx_gpio --disable-am335xgpio \
	--disable-ep93xx --disable-at91rm9200 \
	--disable-vdebug --disable-jtag-dpi \
	--disable-verbose --disable-verbose-usb-io --disable-verbose-usb-comms \
"
