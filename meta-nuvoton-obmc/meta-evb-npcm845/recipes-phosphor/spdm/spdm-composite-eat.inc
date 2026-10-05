# Replace the upstream openbmc/spdm discovery-only stub with NVIDIA's SPDM
# stack (Core-26.05-1_br), which includes an actual libspdmcpp protocol
# engine and can drive real SPDM sessions/measurements, with the in-kernel
# MCTP (AF_MCTP) transport enabled instead of the mctp-demux-daemon socket.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "git://github.com/NVIDIA/spdm.git;branch=Core-26.05-1_br;protocol=https"
SRCREV = "3f5c62011370f3dddc35f006bfb2820014826501"
SRC_URI:append = " file://0001-fix-sdbusplus-api-renames.patch"
SRC_URI:append = " file://0002-publish-authenticating-association-for-ComponentIntegrity.patch"

# BMC-mediated composite attestation (Composite EAT), gated behind the
# composite-eat DISTRO_FEATURE. This adds the vendor-neutral composite/
# core (CBOR claims-set + bundle assembly) plus a mock Lead Attester
# backend, ported from the sibling meta-vr-npcm845 layer's working
# integration onto this same Core-26.05-1_br SRCREV.
SRC_URI:append = " file://0003-spdmd-add-BMC-mediated-composite-attestation-support.patch"
SRC_URI:append = " file://0004-spdmd-address-review-feedback-on-composite-EAT.patch"
SRC_URI:append = " file://0005-spdmd-fix-boost-asio-timer-cancel-api-mismatch.patch"
SRC_URI:append = " file://0006-spdmd-add-bmc-direct-composite-EAT-platform-attester.patch"

# Collection plan mapping discovered SPDM endpoints (MCTP EIDs) to stable
# env.* topology identifiers for the composite EAT. Read by spdmd from
# /etc/spdmd/composite.json. Machine specific because the EIDs differ.
SRC_URI:append = " file://composite.json"

do_install:append() {
    install -d ${D}${sysconfdir}/spdmd
    install -m 0644 ${UNPACKDIR}/composite.json ${D}${sysconfdir}/spdmd/composite.json
}

FILES:${PN}:append = " ${sysconfdir}/spdmd/composite.json"


LIC_FILES_CHKSUM = "file://README.md;md5=f104f1dd1349cfc64bf390d7495ed4a0"

# Note: libmctp is intentionally NOT a dependency. With
# -Denable-in-kernel-mctp=enabled below, spdmcpp's mctp_support.hpp uses the
# kernel's <linux/mctp.h> AF_MCTP socket API directly (its own comment notes
# this "avoid[s] dependency on libmctp-externals.h"); libmctp is only needed
# for the disabled mctp-demux-daemon transport path.
DEPENDS = " \
    systemd \
    sdeventplus \
    phosphor-dbus-interfaces \
    nlohmann-json \
    cli11 \
    mbedtls \
"

# discovery_only_from_mctp_control was enabled to skip the UUID +
# Inventory.Item.SPDMResponder matching path, since nothing in this image
# populated it for the npcm845 MCTP-I2C device; but that path is also the
# only one that resolves a real inventory object (invPath), which
# ComponentIntegrity's "authenticating" association needs
# (0002-publish-authenticating-association-for-ComponentIntegrity.patch).
# Disabled to test end-to-end target resolution.
EXTRA_OEMESON = " \
    -Dtests=disabled \
    -Dfetch_serialnumber_from_responder=26 \
    -Dcsm_service_enabled=disabled \
    -Denable-in-kernel-mctp=enabled \
    -Ddiscovery_only_from_mctp_control=disabled \
"

# Composite EAT opt-in gate (OFF by default). No real Nuvoton RoT/mailbox
# exists in QEMU, so this selects the mock Lead Attester backend (produces
# a real signed-looking bundle without needing hardware) rather than the
# npcm mailbox backend, which needs QEMU-side RoT emulation this session
# doesn't add.
PACKAGECONFIG:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'composite-eat', 'composite-eat', '', d)}"
PACKAGECONFIG[composite-eat] = " \
    -Dcomposite-attestation=enabled -Dattester-backend=bmc-direct-composite-eat, \
    -Dcomposite-attestation=disabled -Dattester-backend=none, \
    tinycbor, \
"
