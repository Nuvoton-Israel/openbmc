FILESEXTRAPATHS:prepend := "${THISDIR}/linux-nuvoton:"

SRC_URI:append:olympus-nuvoton = " file://olympus-nuvoton.cfg"

SRC_URI:remove:olympus-nuvoton = " file://0001-drivers-misc-porting-mcu-flash-driver.patch"
SRC_URI:remove:olympus-nuvoton = " file://0001-Modify-Olympus-PSU-driver-to-inspur-ipsps.c.patch"
