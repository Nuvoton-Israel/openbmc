FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

SRC_URI:append:nuvoton = " file://0008-base-passwd-Add-the-render-group.patch"
