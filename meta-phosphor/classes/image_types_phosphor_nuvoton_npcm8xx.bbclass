MERGED_SUFFIX = "merged"
UBOOT_SUFFIX:append = ".${MERGED_SUFFIX}"

FIT_KERNEL_COMP_ALG:df-obmc-static-norootfs = "gzip"
FIT_KERNEL_COMP_ALG_EXTENSION:df-obmc-static-norootfs = ".gz"

# link images for we only need to flash partial image with idea name
do_generate_ext4_tar:append() {
    cd ${DEPLOY_DIR_IMAGE}
    ln -sf ${IMAGE_NAME}.wic.gz image-emmc.gz
}

# clean up image-u-boot because we may generate different size bootbloder
# with different build flags. Function do_generate_image_uboot_file use
# notrunc flag which may generate redundant image if we don't clean deploy.
do_clean_image_uboot() {
    rm -rf ${IMGDEPLOYDIR}/image-u-boot
}

addtask do_clean_image_uboot after do_rootfs
do_make_ubi[depends] += "npcm8xx-bootloader:do_deploy"
do_generate_static[depends] += " \
    npcm8xx-bootloader:do_deploy \
    ${PN}:do_clean_image_uboot \
"
do_generate_static_norootfs[depends] += "npcm8xx-bootloader:do_deploy"
do_generate_ext4_tar[depends] += "npcm8xx-bootloader:do_deploy"

