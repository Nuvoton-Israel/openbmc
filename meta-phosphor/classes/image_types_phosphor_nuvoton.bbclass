UBOOT_BINARY := "u-boot.${UBOOT_SUFFIX}"
BOOTBLOCK = "Poleg_bootblock.bin"
FULL_SUFFIX = "full"
MERGED_SUFFIX = "merged"
UBOOT_SUFFIX:append = ".${MERGED_SUFFIX}"

IGPS_DIR = "${STAGING_DIR_NATIVE}${datadir}/npcm7xx-igps"

check_keys() {
    if [ -n "${KEY_FOLDER}" ]; then
        echo "local"
    else
        echo "default"
    fi
}

# Prepare the Bootblock and U-Boot images using npcm7xx-bingo
do_prepare_bootloaders() {
    local olddir="$(pwd)"
    cd ${DEPLOY_DIR_IMAGE}
    bingo ${IGPS_DIR}/BootBlockAndHeader_${IGPS_MACHINE}.xml \
            -o ${DEPLOY_DIR_IMAGE}/${BOOTBLOCK}.${FULL_SUFFIX}

    bingo ${IGPS_DIR}/UbootHeader_${IGPS_MACHINE}.xml \
            -o ${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY}.${FULL_SUFFIX}

    # Signature prodedure if necessary
    if [ "${SECURED_IMAGE}" = "True" ]; then
        checked=`check_keys`
        if [ "${checked}" = "local" ]; then
            bbnote "Sign image with local keys"
            key_rsa_pri=${KEY_FOLDER}/${KEY_RSA_PRI}
            key_rsa_pub=${KEY_FOLDER}/${KEY_RSA_PUB}
        else
            bbnote "Sign image with default keys"
            key_rsa_pri=${KEY_FOLDER_DEFAULT}/${KEY_RSA_PRI}
            key_rsa_pub=${KEY_FOLDER_DEFAULT}/${KEY_RSA_PUB}
        fi
        bbnote "rsa prikey from ${checked}: ${key_rsa_pri}"
        bbnote "rsa pubkey from ${checked}: ${key_rsa_pub}"

        res=`python3 ${IGPS_DIR}/BinarySignatureGenerator.py sign_binary \
            ${DEPLOY_DIR_IMAGE}/${BOOTBLOCK}.${FULL_SUFFIX} 320 ${key_rsa_pri} \
            ${key_rsa_pub} 8 ${DEPLOY_DIR_IMAGE}/${BOOTBLOCK}.${FULL_SUFFIX}

            python3 ${IGPS_DIR}/BinarySignatureGenerator.py sign_binary \
            ${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY}.${FULL_SUFFIX} 320 ${key_rsa_pri} \
            ${key_rsa_pub} 8 ${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY}.${FULL_SUFFIX}`

	echo $res
        # stop if signing binary gets failure
        set +e
        err=`echo $res | grep -E "missing|Invalid|failed"`
        if [ -n "${err}" ]; then
            bbfatal "Sign binary failed: keys are not found or invalid."
            bbfatal "Please check your KEY_FOLDER and KEY definition."
        fi
    fi

    bingo ${IGPS_DIR}/mergedBootBlockAndUboot.xml \
            -o ${DEPLOY_DIR_IMAGE}/${UBOOT_BINARY}.${MERGED_SUFFIX}

    # Signature prodedure if necessary
    if [ "${SECURED_IMAGE}" = "True" ]; then
            bingo ${IGPS_DIR}/poleg_key_map.xml \
                  -o ${DEPLOY_DIR_IMAGE}/poleg_key_map.bin
            bingo ${IGPS_DIR}/poleg_fuse_map.xml \
                  -o ${DEPLOY_DIR_IMAGE}/poleg_fuse_map.bin
            bingo ${IGPS_DIR}/mergedFuses.xml \
                  -o ${DEPLOY_DIR_IMAGE}/mergedFuses.bin
            bingo ${IGPS_DIR}/mergedSecureBoot.xml \
                  -o ${DEPLOY_DIR_IMAGE}/mergedBootBlockAndUboot.bin
    fi

    cd "$olddir"
}

do_prepare_bootloaders[depends] += " \
    u-boot:do_deploy \
    npcm7xx-bootblock:do_deploy \
    npcm7xx-bingo-native:do_populate_sysroot \
    npcm7xx-igps-native:do_populate_sysroot \
    "

addtask do_prepare_bootloaders before do_generate_static after do_generate_rwfs_static

# Include the full bootblock and u-boot in the final static image
python do_generate_static:append() {
    _append_image(os.path.join(d.getVar('DEPLOY_DIR_IMAGE', True),
                               'u-boot.%s' % d.getVar('UBOOT_SUFFIX',True)),
                  int(d.getVar('FLASH_UBOOT_OFFSET', True)),
                  int(d.getVar('FLASH_KERNEL_OFFSET', True)))
}

do_make_ubi:append() {
    # Concatenate the uboot and ubi partitions
    dd bs=1k conv=notrunc seek=${FLASH_UBOOT_OFFSET} \
        if=${DEPLOY_DIR_IMAGE}/u-boot.${UBOOT_SUFFIX} \
        of=${IMGDEPLOYDIR}/${IMAGE_NAME}.ubi.mtd
}

# link images for we only need to flash partial image with idea name
do_generate_ext4_tar:npcm7xx() {
    # Generate the U-Boot image, and ignore empty zero
    # mk_empty_image_zeros image-u-boot ${MMC_UBOOT_SIZE}
    do_generate_image_uboot_file image-u-boot

    # Generate a compressed ext4 filesystem with the fitImage file in it to be
    # flashed to the boot partition of the eMMC
    install -d boot-image
    install -m 644 ${DEPLOY_DIR_IMAGE}/${FLASH_KERNEL_IMAGE} boot-image/fitImage
    mk_empty_image_zeros boot-image.${FLASH_EXT4_BASETYPE} ${MMC_BOOT_PARTITION_SIZE}
    mkfs.ext4 -F -i 4096 -d boot-image boot-image.${FLASH_EXT4_BASETYPE}
    # Error codes 0-3 indicate successfull operation of fsck
    fsck.ext4 -pvfD boot-image.${FLASH_EXT4_BASETYPE} || [ $? -le 3 ]
    zstd -f -k -T0 -c ${ZSTD_COMPRESSION_LEVEL} boot-image.${FLASH_EXT4_BASETYPE} > boot-image.${FLASH_EXT4_BASETYPE}.zst

    # Generate the compressed ext4 rootfs
    zstd -f -k -T0 -c ${ZSTD_COMPRESSION_LEVEL} ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${FLASH_EXT4_BASETYPE} > ${IMAGE_LINK_NAME}.${FLASH_EXT4_BASETYPE}.zst

    ln -sf boot-image.${FLASH_EXT4_BASETYPE}.zst image-kernel
    ln -sf ${IMAGE_LINK_NAME}.${FLASH_EXT4_BASETYPE}.zst image-rofs
    ln -sf ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.rwfs.${FLASH_EXT4_OVERLAY_BASETYPE} image-rwfs
    ln -sf ${S}/MANIFEST MANIFEST
    ln -sf ${S}/publickey publickey

    make_signatures image-u-boot image-kernel image-rofs image-rwfs MANIFEST publickey
    make_tar_of_images ext4.mmc MANIFEST publickey ${signature_files}

    cd ${DEPLOY_DIR_IMAGE}
    ln -sf ${UBOOT_BINARY}.${MERGED_SUFFIX} image-u-boot
    ln -sf ${DEPLOY_DIR_IMAGE}/${FLASH_KERNEL_IMAGE} image-kernel
    ln -sf ${S}/ext4/${IMAGE_LINK_NAME}.${FLASH_EXT4_BASETYPE}.zst image-rofs
    ln -sf ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.rwfs.${FLASH_EXT4_OVERLAY_BASETYPE} image-rwfs
    # if "wic.gz" in d.getVar('IMAGE_FSTYPES')
    wic_gz="${@bb.utils.contains('IMAGE_FSTYPES', 'wic.gz', 'yes', '', d)}"
    if [ -n "$wic_gz" ];then
        ln -sf ${IMAGE_NAME}.wic.gz image-emmc.gz
    elif [ -h image-emmc.gz ];then
        rm -f image-emmc.gz
    fi
}

do_make_ubi[depends] += "${PN}:do_prepare_bootloaders"
do_generate_ubi_tar[depends] += "${PN}:do_prepare_bootloaders"
do_generate_static_tar[depends] += "${PN}:do_prepare_bootloaders"
do_generate_ext4_tar[depends] += "${PN}:do_prepare_bootloaders"
