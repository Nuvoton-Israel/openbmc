SUMMARY = "TIP FW for NPCM8XX (Arbel) devices, built from source"
DESCRIPTION = "Cerberus port to the Nuvoton TIP enclave. The sources are \
spread over three repositories which upstream assembles with the Google \
`repo` tool, see npcm8xx-tip-fw-manifest/default.xml. We reproduce that \
layout with destsuffix so no extra tooling is needed. The resulting raw \
L0/L1 images are unsigned, npcm8xx-bootloader hands them to IGPS which \
signs them together with the rest of the boot chain."
HOMEPAGE = "https://github.com/Nuvoton-Israel/npcm8xx-tip"
LICENSE = "MIT & Apache-2.0"
LIC_FILES_CHKSUM = " \
    file://LICENSE.txt;md5=323954e5c90a1cc83ee74a3797f8d988 \
    file://projects/nuvoton/LICENSE;md5=86d3f3a95c324c9479bd8986968f4327 \
    file://external/mbedtls/LICENSE;md5=379d5819937a6c2f1ef1630d341e026d \
"

CERBERUS_BRANCH ?= "core-igps"
TIP_BRANCH ?= "main_nuvoton"

SRC_URI = " \
    git://github.com/Nuvoton-Israel/npcm8xx-tip-fw-project-cerberus;name=cerberus;protocol=https;branch=${CERBERUS_BRANCH};destsuffix=cerberus \
    git://github.com/Nuvoton-Israel/npcm8xx-tip;name=tip;protocol=https;branch=${TIP_BRANCH};destsuffix=cerberus/projects/nuvoton \
    git://github.com/Mbed-TLS/mbedtls;name=mbedtls;protocol=https;nobranch=1;destsuffix=cerberus/external/mbedtls \
"
SRCREV_FORMAT = "cerberus_tip_mbedtls"

S = "${UNPACKDIR}/cerberus"
B = "${WORKDIR}/build"

# The TIP runs on a Cortex-M4 enclave, nothing here is built for the BMC
# target, so keep the target toolchain out of the picture entirely.
INHIBIT_DEFAULT_DEPS = "1"
DEPENDS = "cmake-native ninja-native gcc-arm-none-eabi-native"

CC[unexport] = "1"
CXX[unexport] = "1"
CPP[unexport] = "1"
CFLAGS[unexport] = "1"
CXXFLAGS[unexport] = "1"
CPPFLAGS[unexport] = "1"
LDFLAGS[unexport] = "1"
AS[unexport] = "1"
LD[unexport] = "1"
AR[unexport] = "1"
NM[unexport] = "1"
RANLIB[unexport] = "1"
OBJCOPY[unexport] = "1"
OBJDUMP[unexport] = "1"
STRIP[unexport] = "1"

TIP_SRC_BASE = "${S}/projects/nuvoton/tip/npcm850"
TIP_LEVELS = "L0 L1"

# The upstream CMakeLists call project() before including the bare-metal
# toolchain file, so the compiler probe would otherwise run with the host
# compiler and link a full executable. Seed both from the command line.
EXTRA_OECMAKE = " \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_COMPILER=arm-none-eabi-gcc \
    -DCMAKE_ASM_COMPILER=arm-none-eabi-gcc \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
"

do_configure() {
    for level in ${TIP_LEVELS}; do
        cmake ${EXTRA_OECMAKE} -B ${B}/$level -S ${TIP_SRC_BASE}/$level
    done
}

do_compile() {
    for level in ${TIP_LEVELS}; do
        ninja -C ${B}/$level
    done
}

do_install[noexec] = "1"

# The TIP images are only deployed for npcm8xx-bootloader to pick up, nothing
# is installed on the BMC rootfs, so skip packaging altogether.
#
# Note the recipe is deliberately not called npcm8xx-tip-fw-src: the default
# PACKAGE_DEBUG_SPLIT_STYLE of "debug-with-srcpkg" makes every recipe emit a
# "${PN}-src" package, so that name is already owned by npcm8xx-tip-fw and
# the two would collide in the shared pkgdata area.
inherit deploy nopackages
do_deploy() {
    for level in ${TIP_LEVELS}; do
        install -D -m 644 ${B}/$level/arbel_tip_fw_$level.bin \
            ${DEPLOYDIR}/arbel_tip_fw_$level.bin
    done
}

addtask deploy before do_build after do_compile

PACKAGE_ARCH = "${MACHINE_ARCH}"
