inherit entity-utils

FILESEXTRAPATHS:prepend:nuvoton := "${THISDIR}/${PN}:"

# ComponentIntegrity and BMC-mediated Composite EAT OEM API
SRC_URI:append:df-composite-eat = " \
    file://0001-redfish-add-ComponentIntegrity-resources.patch \
    file://0002-redfish-discover-component-integrity-by-interface.patch \
    file://0003-redfish-add-platform-Composite-EAT-API.patch \
    file://0004-http-prefer-literal-routes-over-parameters.patch \
    file://0005-redfish-harden-ComponentIntegrity-and-Composite-EAT.patch \
    "

# Enable Redfish DBUS log/Journal support
EXTRA_OEMESON:append = " ${@entity_enabled(d, '-Dredfish-bmc-journal=enabled', '-Dredfish-dbus-log=enabled')}"

# Increase body limit for FW size
EXTRA_OEMESON:append  = " -Dhttp-body-limit=65"

# Enable dbus rest API /xyz/
EXTRA_OEMESON:append = " -Drest=enabled"

# Enalbe sensors
EXTRA_OEMESON:append = " -Dredfish-new-powersubsystem-thermalsubsystem=enabled"

# BMC-mediated Composite EAT OEM API (OpenBMCCompositeEATBundle.Generate and
# the CompositeEATBundle result resource). Gated on the same composite-eat
# DISTRO_FEATURE that enables the spdmd producer side; without this the OEM
# route is compiled out and returns 404. Requires redfish-component-integrity,
# which the Meson build enforces.
EXTRA_OEMESON:append:df-composite-eat = " -Dredfish-component-integrity=enabled"
EXTRA_OEMESON:append:df-composite-eat = " -Dredfish-composite-eat=enabled"

# Enable debug
# EXTRA_OEMESON:append = " -Dbmcweb-logging=enabled"
