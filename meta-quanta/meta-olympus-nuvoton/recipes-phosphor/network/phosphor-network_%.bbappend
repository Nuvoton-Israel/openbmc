FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json"

EXTRA_OECONF_append_olympus-nuvoton = " --disable-link-local-autoconfiguration --with-uboot-env"

SRC_URI_append_olympus-nuvoton = " file://0001-Run-after-xyz-openbmc_project-user-path-created.patch"
SRC_URI_append_olympus-nuvoton = " file://0003-remove-ethernet-disable-enable-control.patch"
