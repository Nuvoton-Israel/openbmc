FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-nuvoton:"

inherit emmc-utils
SRC_URI:append = " file://scm.cfg"
SRC_URI:append:scm-npcm845 = " file://nuvoton-npcm845-scm-pincfg.dtsi;subdir=git/arch/arm/dts/"
SRC_URI:append:scm-npcm845 = " file://nuvoton-npcm845-scm.dts;subdir=git/arch/arm/dts/"
SRC_URI:append:scm-npcm845 = " file://0001-add-w25q512nw-support.patch"
SRC_URI:append:scm-npcm845 = " file://0012-Enable-DVO-HSYNC-DDC-i2c-port-and-don-t-reset-GPIO1-.patch"
SRC_URI:append:scm-npcm845 = " file://0002-add-i2c-voltage-1.8v-support.patch"

SRC_URI:append:scm-npcm845 = " file://0001-uboot-scm-dts.patch"
SRC_URI:append:scm-npcm845 = " \
	${@emmc_enabled(d, 'file://1111-boot-openbmc-form-emmc.patch file://mmc-boot.cfg')}"

SRC_URI:append:m1120-c2195 = " file://m1120.dts;subdir=git/arch/arm/dts/"
SRC_URI:append:m1120-c2195 = " file://m1120-pincfg.dtsi;subdir=git/arch/arm/dts/"
SRC_URI:append:m1120-c2195 = " file://0001-uboot-m1120-dts-makefile.patch"
SRC_URI:append:m1120-c2195 = " file://0002-Add-smb23b-pin-define.patch"
SRC_URI:append:m1120-c2195 = " file://0012-Enable-DVO-HSYNC-DDC-i2c-port-and-don-t-reset-GPIO1-.patch"
