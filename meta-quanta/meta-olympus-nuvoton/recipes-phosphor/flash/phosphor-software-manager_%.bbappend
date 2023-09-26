FILESEXTRAPATHS:prepend:olympus-nuvoton := "${THISDIR}/${PN}:"


#SRC_URI:append:olympus-nuvoton = " file://avoid_update_bios_fail_remove_mmc"
SRC_URI:append:olympus-nuvoton = " file://0001-Add-support-for-PSU-firmware-upgrade.patch"
SRC_URI:append:olympus-nuvoton = " file://0002-Add-support-report-same-version-error.patch"

PACKAGECONFIG:append:olympus-nuvoton = " verify_signature flash_bios"
EXTRA_OEMESON:append:olympus-nuvoton = " -Doptional-images=image-bios"
