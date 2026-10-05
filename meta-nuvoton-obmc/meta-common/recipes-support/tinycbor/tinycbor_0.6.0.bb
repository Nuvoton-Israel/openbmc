SUMMARY = "TinyCBOR - Concise Binary Object Representation (RFC 8949) library"
DESCRIPTION = "Small, self-contained C library for encoding and decoding CBOR. \
Required by the NVIDIA/spdm composite-attestation producer for deterministic \
CBOR (Claims-Set and Detached EAT Bundle) construction."
HOMEPAGE = "https://github.com/intel/tinycbor"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6c1ac30774dd6476b42b5b020cd2aa5f"

SRC_URI = "git://github.com/intel/tinycbor.git;protocol=https;branch=main"
SRCREV = "d393c16f3eb30d0c47e6f9d92db62272f0ec4dc7"

PV = "0.6.0"

# Upstream ships plain Makefiles; honour the cross toolchain and install paths.
# Command-line overrides take precedence over the Makefile's own CFLAGS=.
EXTRA_OEMAKE = " \
    prefix=${prefix} \
    libdir=${libdir} \
    includedir=${includedir} \
    bindir=${bindir} \
    pkgconfigdir=${libdir}/pkgconfig \
    CC='${CC}' \
    AR='${AR}' \
    CFLAGS='${CFLAGS}' \
    LDFLAGS='${LDFLAGS}' \
"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake install DESTDIR=${D}
}
