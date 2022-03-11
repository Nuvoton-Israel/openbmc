SUMMARY = "OP-TEE Trusted OS"
DESCRIPTION = "OPTEE OS"

LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=c1f21c4f72f372ef38a5a4aee55ec173"

PV="1.0.0+git${SRCPV}"

inherit deploy python3native
DEPENDS = "python3-pyelftools-native python3-pycryptodome-native python3-cryptography-native"

S = "${WORKDIR}/git"
BRANCH ?= "nuvoton"
REPO ?= "git://github.com/Nuvoton-Israel/optee_os.git;protocol=https"
BRANCHARG = "${@['nobranch=1', 'branch=${BRANCH}'][d.getVar('BRANCH', True) != '']}"
SRC_URI = "${REPO};${BRANCHARG} \           
	   file://0001-allow-sysroot-for-libgcc-lookup.patch \
          "
SRCREV = "6b716e224f6162ea37d549ef42aaf3b165423716"

COMPATIBLE_MACHINE = "(evb-npcm845)"
OPTEEMACHINE ?= "nuvoton"
#MACHINE ?= "npcm8xx"
MACHINE_SOC ?= "npcm8xx"

# Some versions of u-boot use .bin and others use .img.  By default use .bin
# but enable individual recipes to change this value.
OPTEE_SUFFIX ?= "bin"
OPTEE_IMAGE ?= "tee-${MACHINE_SOC}-${PV}-${PR}.${OPTEE_SUFFIX}"
OPTEE_SYMLINK ?= "tee-${MACHINE_SOC}.${OPTEE_SUFFIX}"
CFG_TEE_TA_LOG_LEVEL ?= "1"
CFG_TEE_CORE_LOG_LEVEL ?= "1"

EXTRA_OEMAKE = "PLATFORM=${OPTEEMACHINE} CFG_ARM64_core=y \
                CROSS_COMPILE_core=${HOST_PREFIX} \
                CROSS_COMPILE_ta_arm64=${HOST_PREFIX} \
                NOWERROR=1 \
                ta-targets=ta_arm64 \
                LDFLAGS= \
                LIBGCC_LOCATE_CFLAGS=--sysroot=${STAGING_DIR_HOST} \
        "

OPTEE_ARCH_aarch64 = "arm64"

do_compile() {
    unset LDFLAGS
    oe_runmake CFG_TEE_LOGLEVEL=0 CFG_TEE_CORE_LOG_LEVEL=0
}

# do_install() nothing
do_install[noexec] = "1"

#PACKAGE_ARCH = "${MACHINE_ARCH}"

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${S}/out/arm-plat-${OPTEEMACHINE}/core/tee.bin ${DEPLOYDIR}/tee.bin
    cd ${DEPLOYDIR}
    ln -sf tee.bin ${OPTEE_SYMLINK}
    ln -sf tee.bin ${OPTEE_IMAGE}
}

addtask deploy before do_build after do_compile
