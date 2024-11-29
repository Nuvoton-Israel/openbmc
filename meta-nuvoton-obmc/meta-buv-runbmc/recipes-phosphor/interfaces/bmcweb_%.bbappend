inherit entity-utils

FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://0001-Implement-Power-Equipment-Distribution-Supply-Supply.patch"

# Enable Redfish DBUS log/Journal support
EXTRA_OEMESON:append:buv-runbmc = " ${@entity_enabled(d, '-Dredfish-bmc-journal=enabled', '-Dredfish-dbus-log=enabled')}"

# Increase body limit for BIOS FW
EXTRA_OEMESON:append:buv-runbmc = " -Dhttp-body-limit=65"

# enable debug
# EXTRA_OEMESON:append:buv-runbmc = " -Dbmcweb-logging=enabled"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append:buv-runbmc = " -Drest=enabled"

EXTRA_OEMESON:append:buv-runbmc = " -Dredfish-new-powersubsystem-thermalsubsystem=enabled"
