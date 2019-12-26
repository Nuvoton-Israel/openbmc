EXTRA_OECONF_olympus-nuvoton += " --disable-link-local-autoconfiguration"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

DEPENDS += "nlohmann-json"

SRC_URI += "git://github.com/openbmc/phosphor-networkd"
SRC_URI += "file://0003-Adding-channel-specific-privilege-to-network.patch \
            "
SRC_URI += "file://0001-fix-mac-address-missing-left-zeros.patch"

SRCREV = "cb42fe26febc9e457a9c4279278bd8c85f60851a"
