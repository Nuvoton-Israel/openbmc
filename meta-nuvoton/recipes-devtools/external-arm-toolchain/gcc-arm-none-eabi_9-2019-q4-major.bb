require recipes-devtools/external-arm-toolchain/arm-binary-toolchain.inc

COMPATIBLE_HOST = "x86_64.*-linux"

SUMMARY = "GNU Arm Embedded Toolchain - AArch32 bare-metal target (arm-none-eabi)"
DESCRIPTION = "Kept alongside the newer toolchains in meta-arm-toolchain because \
the NPCM8XX TIP FW sources are only validated against this release, see the \
build instructions in npcm8xx-tip/README.md. Newer compilers reject the \
sources outright, as the upstream CMake flags include -Wall -Wextra -Werror \
and -Wl,--fatal-warnings."
LICENSE = "GPL-3.0-with-GCC-exception & GPL-3.0-only"
LIC_FILES_CHKSUM = "file://share/doc/gcc-arm-none-eabi/license.txt;md5=c18349634b740b7b95f2c2159af888f5"

SRC_URI = "https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-${PV}-${HOST_ARCH}-linux.tar.bz2;name=gcc-${HOST_ARCH}"
SRC_URI[gcc-x86_64.sha256sum] = "bcd840f839d5bf49279638e9f67890b2ef3a7c9c7a9b25271e83ec4ff41d177a"

S = "${UNPACKDIR}/gcc-arm-none-eabi-${PV}"

UPSTREAM_CHECK_URI = "https://developer.arm.com/downloads/-/gnu-rm"
