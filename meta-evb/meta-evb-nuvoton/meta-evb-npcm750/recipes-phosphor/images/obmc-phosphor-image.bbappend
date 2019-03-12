inherit npcm7xx-image

FLASH_UBOOT_OFFSET = "0"
FLASH_KERNEL_OFFSET = "2048"
FLASH_UBI_OFFSET = "${FLASH_KERNEL_OFFSET}"
FLASH_ROFS_OFFSET = "7680"
FLASH_RWFS_OFFSET = "30720"

# UBI volume sizes in KB unless otherwise noted.
FLASH_UBI_RWFS_SIZE = "6144"
FLASH_UBI_RWFS_TXT_SIZE = "6MiB"

SIGNING_KEY = "${STAGING_DIR_NATIVE}${datadir}/Nuvoton.priv"
SIGNING_KEY_DEPENDS = "phosphor-nuvoton-signing-key-native:do_populate_sysroot"

# start generate mtd image only after scrits, tools and inputs are ready
do_generate_static[depends] += " \
        u-boot-fw-utils-nuvoton:do_populate_sysroot \
        u-boot-nuvoton:do_deploy          \
        npcm750-bootblock:do_deploy                 \
        npcm7xx-signit-native:do_populate_sysroot   \
        npcm7xx-bingo-native:do_populate_sysroot    \
        npcm7xx-uut-native:do_populate_sysroot      \
        npcm7xx-igps-native:do_populate_sysroot     \
        "

# do_generate_ubi/static_tar will use the outputs of do_generate_static
do_generate_ubi_tar[depends] += "${PN}:do_generate_static"
do_generate_static_tar[depends] += "${PN}:do_generate_static"

do_prepare_merged_bb_uboot () {

	# take Nuvoton's EB inputs
	python ${IGPS_DIR}/UpdateInputsBinaries_EB.py

	# override bootblock and u-boot with the images built by openbmc
	cp ${BOOTBLOCK_BIN} ${IGPS_IMAGE_GENERATION_DIR}/inputs/
	cp ${UBOOT_BIN} ${IGPS_IMAGE_GENERATION_DIR}/inputs/

	# generate merged bootblock and u-boot image (including their headers)
	python ${IGPS_DIR}/GenerateAll.py

	# get the merged image
	cp ${IGPS_OUTPUT_MERGED_BIN} ${UBOOT_BIN}.merged

	# rename the merged image to be the "real" u-boot, later will be used
	# by do_generate_static (after will be restored)  
	cp ${UBOOT_BIN} ${UBOOT_BIN}.plan 
	cp ${UBOOT_BIN}.merged ${UBOOT_BIN}
}

do_restore_uboot () {

	# rename the plan u-boot to be the default (for the nex builds) 
	cp ${UBOOT_BIN}.plan ${UBOOT_BIN}
}

do_generate_static_prepend () {

    bb.build.exec_func("do_prepare_merged_bb_uboot", d)
}

do_generate_ubi_tar_append () {

    do_restore_uboot
}

make_image_links_append () {
	# link image-u-boot-merged under obmc-phosphor-image folder to u-boot.bin.merged
	ln -sf ${DEPLOY_DIR_IMAGE}/u-boot.${UBOOT_SUFFIX}.merged image-u-boot
}

do_mk_static_symlinks_append () {
	# link image-u-boot-merged under deploy folder to u-boot.bin.merged
	ln -sf u-boot.${UBOOT_SUFFIX}.merged ${IMGDEPLOYDIR}/image-u-boot
}
