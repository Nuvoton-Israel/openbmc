FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/linux-nuvoton:"
inherit buv-entity-utils

SRC_URI:append:buv-runbmc = " file://buv-runbmc.cfg"
SRC_URI:append:buv-runbmc = " file://enable-usb-xceiv.cfg"

SRC_URI:append:buv-runbmc = " ${@distro_enabled(d, 'kdump', 'file://kdump.cfg')}"

SRC_URI:append:buv-runbmc = " file://0008-driver-misc-seven-segment-display-gpio-driver.patch"
SRC_URI:append:buv-runbmc = " file://0009-Add-buv-runbmc-PSU-driver-inspur-ipsps.c.patch"
SRC_URI:append:buv-runbmc = " file://0010-dts-add-two-test-PSUs-settings.patch"
SRC_URI:append:buv-runbmc = " file://0012-Don-t-use-Write_PROTECT-command-in-chicony-psu.patch"
SRC_URI:append:buv-runbmc = " file://0013-drivers-pmbus-modify-fw_version-command-code.patch"