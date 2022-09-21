SUMMARY = "OP-TEE Trusted OS"
DESCRIPTION = "OPTEE OS"

LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=c1f21c4f72f372ef38a5a4aee55ec173"

PV="1.0.0+git${SRCPV}"

inherit deploy python3native
DEPENDS = "python3-pycryptodome-native python3-pyelftools-native python3-pycryptodomex-native python3-cryptography-native"

do_compile[depends] += "ftpm-ta:do_install"
EXTRA_OEMAKE:append:task-compile = " EARLY_TA_PATHS=${TMPDIR}/optee/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf "

S = "${WORKDIR}/git"
BRANCH ?= "nuvoton"
REPO ?= "git://github.com/Nuvoton-Israel/optee_os.git;branch=nuvoton;protocol=https"
BRANCHARG = "${@['nobranch=1', 'branch=${BRANCH}'][d.getVar('BRANCH', True) != '']}"
SRC_URI = "${REPO};${BRANCHARG} \           
	   file://0001-allow-sysroot-for-libgcc-lookup.patch \
          "
SRCREV = "6d2cdcf8e9c660751fc656b45ee631ade8d956e4"

OPTEEMACHINE ?= "nuvoton"
MACHINE_SOC ?= "npcm8xx"

# Some versions of u-boot use .bin and others use .img.  By default use .bin
# but enable individual recipes to change this value.
OPTEE_SUFFIX ?= "bin"
OPTEE_IMAGE ?= "tee-${MACHINE_SOC}-${PV}-${PR}.${OPTEE_SUFFIX}"
OPTEE_SYMLINK ?= "tee-${MACHINE_SOC}.${OPTEE_SUFFIX}"
CFG_TEE_TA_LOG_LEVEL ?= "1"
CFG_TEE_CORE_LOG_LEVEL ?= "1"

EXPORT_TA_PATH = "${TMPDIR}/optee"
OPTEEOUT_DIR = "${B}/out/arm-plat-nuvoton/export-ta_arm64"

EXTRA_OEMAKE = "PLATFORM=${OPTEEMACHINE} CFG_ARM64_core=y \
                CROSS_COMPILE_core=${HOST_PREFIX} \
                CROSS_COMPILE_ta_arm64=${HOST_PREFIX} \
                NOWERROR=1 \
                ta-targets=ta_arm64 \
                LDFLAGS= \
                LIBGCC_LOCATE_CFLAGS=--sysroot=${STAGING_DIR_HOST} \
                CFG_REE_FS=n \
                CFG_REE_FS_TA=n \
                CFG_RPMB_FS=y \
                CFG_RPMB_TESTKEY=n \
                CFG_RPMB_WRITE_KEY=n \
                CFG_CORE_HEAP_SIZE=524288 \
                CFG_TEE_RAM_VA_SIZE=3145728 \
        "

OPTEE_ARCH_aarch64 = "arm64"

do_compile() {
    unset LDFLAGS
    oe_runmake CFG_TEE_LOGLEVEL=0 CFG_TEE_CORE_LOG_LEVEL=0
}

do_install() {
    # Install the TA devkit
    install -d ${D}/usr/include/optee/export-user_ta/

    for f in ${B}/out/arm-plat-nuvoton/export-ta_arm64/*; do
        cp -aR $f ${D}/usr/include/optee/export-user_ta/
    done
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${S}/out/arm-plat-${OPTEEMACHINE}/core/tee.bin ${DEPLOYDIR}/tee.bin
    cd ${DEPLOYDIR}
    ln -sf tee.bin ${OPTEE_SYMLINK}
    ln -sf tee.bin ${OPTEE_IMAGE}
}

do_export_kit() {
    unset LDFLAGS
    oe_runmake --directory=${S} ${PARALLEL_MAKE}
    #Wipe the old directory
    rm -rf ${EXPORT_TA_PATH}
    mkdir ${EXPORT_TA_PATH}
    #Copy the export directory to a fixed location
    cp -r ${OPTEEOUT_DIR} ${EXPORT_TA_PATH}/export-dev_kit
    #Wipe the directory again to return to previous state
    oe_runmake --directory=${S} clean
}

addtask deploy before do_build after do_compile
addtask do_export_kit before do_compile after do_configure

FILES:${PN} = "${nonarch_base_libdir}/firmware/ ${nonarch_base_libdir}/optee_armtz/"
FILES:${PN}-staticdev = "/usr/include/optee/"
RDEPENDS:${PN}-dev += "${PN}-staticdev"

PACKAGE_ARCH = "${MACHINE_ARCH}"
