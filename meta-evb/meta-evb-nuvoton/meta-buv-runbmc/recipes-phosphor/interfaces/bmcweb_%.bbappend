inherit buv-entity-utils

FILESEXTRAPATHS:prepend:buv-runbmc := "${THISDIR}/${PN}:"

SRC_URI:append:buv-runbmc = " file://0001-Implements-PowerSubsystem-schema.patch"
SRC_URI:append:buv-runbmc = " file://0002-Implements-Power-Equipment-Distribution-Supply-Suppl.patch"
SRC_URI:append:buv-runbmc = " file://0003-Implement-fan-spped-rpm-support.patch"
SRC_URI:append:buv-runbmc = " file://0004-Add-Replaceable-and-FirmwareVersion-to-PowerShelves.patch"

# Enable Redfish DBUS log/Journal support
EXTRA_OEMESON:append:buv-runbmc = " ${@entity_enabled(d, '-Dredfish-bmc-journal=enabled', '-Dredfish-dbus-log=enabled')}"

# Enable TFTP
EXTRA_OEMESON:append:buv-runbmc = " -Dinsecure-tftp-update=enabled"

# Increase body limit for BIOS FW
EXTRA_OEMESON:append:buv-runbmc = " -Dhttp-body-limit=65"

# enable debug
# EXTRA_OEMESON:append:buv-runbmc = " -Dbmcweb-logging=enabled"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append:buv-runbmc = " -Drest=enabled"

EXTRA_OEMESON:append:buv-runbmc = " -Dredfish-new-powersubsystem-thermalsubsystem=enabled"
