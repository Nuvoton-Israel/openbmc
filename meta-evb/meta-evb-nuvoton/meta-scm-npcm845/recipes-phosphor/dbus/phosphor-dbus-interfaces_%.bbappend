FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0024-Add-the-pre-timeout-interrupt-defined-in-IPMI-spec.patch \
    file://0025-Add-PreInterruptFlag-properity-in-DBUS.patch \
"
