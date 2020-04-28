EXTRA_OECONF_olympus-nuvoton += " --disable-link-local-autoconfiguration"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json"

SRC_URI_append_olympus-nuvoton = " file://0001-Run-after-xyz-openbmc_project-user-path-created.patch"
SRC_URI_append_olympus-nuvoton = " file://0002-Adding-channel-specific-privilege-to-network.patch"
SRC_URI_append_olympus-nuvoton = " file://0004-Backend-changes-for-Populating-Nameservers-DNS-Stati.patch"
SRC_URI_append_olympus-nuvoton = " file://0001-meta-quanta-olympus-nuvoton-phosphor-network.patch"
