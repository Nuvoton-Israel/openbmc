SUMMARY = "Lightweight Composite EAT SDK for BMC integration"
DESCRIPTION = "Transport-independent C reference SDK for integrating a BMC \
attestation collector (spdmd) with a platform Root of Trust that generates \
signed Composite EAT main tokens. Provides the private BMC-to-RoT \
generation-request codec, the split-phase Composite EAT token builder, and an \
optional TCG DICE Concise Evidence helper."

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

PV = "0.2.0+git${SRCPV}"

SRC_URI = "git://git@github.com/helloxiling/bmc-composite-eat-sdk.git;protocol=ssh;branch=main"
SRCREV = "ef3aadb65503c80d6d894a76549c20ce5d9e1800"

inherit cmake pkgconfig

# The vendored QCBOR subset builds offline; no network fetch is required.
# Package the library (Phase 1): static core libs, headers, and CMake config.
# Tests and examples stay disabled so the default image ships only the codec
# and token-builder core, per the SDK integration guide.
EXTRA_OECMAKE = " \
    -DBMC_COMPOSITE_EAT_BUILD_TESTS=OFF \
    -DBMC_COMPOSITE_EAT_BUILD_EXAMPLES=OFF \
    "

# The SDK exports only static archives (no shared object or executable), so the
# consumable artifacts live in the -dev and -staticdev packages.
FILES:${PN}-dev += "${datadir}/bmc-composite-eat"

# Static libraries carry TMPDIR references in their debug info; the same skip is
# used by other static-lib recipes in this layer set.
INSANE_SKIP:${PN}-staticdev += "buildpaths"

# Header-only/static consumers link these targets:
#   bmc::composite_eat        - token builder
#   bmc::generation_request   - BMC-to-RoT CBOR generation-request codec
#   bmc::tcg_concise_evidence - optional TCG DICE Concise Evidence serializer
