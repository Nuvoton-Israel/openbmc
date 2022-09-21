DESCRIPTION = "fTPM Trusted Application"
SECTION = "TA"

LICENSE = "CLOSED"

DEPENDS = "python3-pycryptodome-native python3-pyelftools-native python3-cryptography-native"
inherit python3native
do_compile[depends] += "optee-os:do_export_kit"

PR = "r0"

FTPM_SRC_BRANCH ?= "master"

SRC_URI = "gitsm://github.com/microsoft/MSRSec.git;branch=master;protocol=https \
           file://0001-Mark-TA-discoverable.patch \
           "

SRCREV = "81abeb9fa968340438b4b0c08aa6685833f0bfa1"

S = "${WORKDIR}/git"

PARALLEL_MAKE = ""
BUILD_DIR = "TAs/optee_ta"

TA_UID = "bc50d971-d4c9-42c4-82cb-343fb7f37896"

OPTEE_EXPORT_USR_TA_DIR = "${TMPDIR}/optee"
BUILD_ONLY_FTPM = "ftpm"

EXTRA_OEMAKE = "TA_DEV_KIT_DIR=${OPTEE_EXPORT_USR_TA_DIR}/export-dev_kit \
                TA_CROSS_COMPILE=${TARGET_PREFIX} \
                AR=${TARGET_PREFIX}ar \
                RANLIB=${TARGET_PREFIX}ranlib \
                RC=${TARGET_PREFIX}rc \
                TA_CPU=cortex-a35+crypto \
                CFG_TEE_CORE_DEBUG=n \
                CFG_TEE_CORE_LOG_LEVEL=0 \
                CFG_TEE_CORE_TA_TRACE=0 \
                CFG_TA_DEBUG=n \
                CFG_TEE_TA_LOG_LEVEL=0 \
                CFG_ARM64_ta_arm64=y \
                CFG_FTPM_USE_WOLF=n \
                CFG_AUTHVARS_USE_WOLF=n \
                LIBGCC_LOCATE_CFLAGS=--sysroot=${STAGING_DIR_HOST}"

do_compile() {
    BUILD_PATH=${B}/${BUILD_DIR}
    bbnote 'Building fTPM TA'
    oe_runmake $BUILD_ONLY_FTPM --directory=$BUILD_PATH
}

do_install() {
    OUTPUT_DIR=${B}/${BUILD_DIR}/out/fTPM
    OBJECT_FILE=${TA_UID}.stripped.elf
    cp $OUTPUT_DIR/$OBJECT_FILE ${OPTEE_EXPORT_USR_TA_DIR}
}
