inherit npcm7xx-image

FLASH_UBOOT_OFFSET = "0"
FLASH_KERNEL_OFFSET = "2048"
FLASH_UBI_OFFSET = "${FLASH_KERNEL_OFFSET}"
FLASH_ROFS_OFFSET = "7680"
FLASH_RWFS_OFFSET = "30720"
FLASH_FIT_KERNEL_RO = "image-kernel-rofs"

# UBI volume sizes in KB unless otherwise noted.
FLASH_UBI_RWFS_SIZE = "6144"
FLASH_UBI_RWFS_TXT_SIZE = "6MiB"

#SIGNING_KEY = "${STAGING_DIR_NATIVE}${datadir}/Nuvoton.key"
#SIGNING_KEY_DEPENDS = "phosphor-nuvoton-signing-key-native:do_populate_sysroot"

OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-host"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-kcs"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-net"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-cooling-type"

IMAGE_INSTALL_append = " bmcweb \
                         obmc-ikvm \
                         phosphor-webui \
                         phosphor-ipmi-host \
                         phosphor-ipmi-ipmb-legacy \
                         lmsensors-fancontrol \
                         lmsensors-pwmconfig \
                         lmsensors-sensord \
                         lmsensors-sensors \
                         iperf2 \
                         phosphor-image-signing \
                         x86-power-control \
                         obmc-mgr-system \
                         obmc-mgr-inventory \
                         evb-npcm750-config \
                         obmc-libobmc-intf \
                         obmc-phosphor-buttons \
                         python-ldap \
                         openldap-bin \
			 loadsvf \   
                       "

# start generate mtd image only after scrits, tools and inputs are ready 
do_generate_static[depends] += " \
        u-boot-fw-utils-nuvoton:do_populate_sysroot \
        u-boot-nuvoton:do_populate_sysroot          \
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

	cd ${DEPLOY_DIR_IMAGE}
	ln -sf ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMAGE_BASETYPE} image-rofs-pure

	#
	# Assemble the FIT image and sign kenel dtb initramfs rofs with key under ${DEPLOY_DIR_IMAGE}/uboot_fitkey
	#
	cp ${DEPLOY_DIR_IMAGE}/fitImage-its-${INITRAMFS_IMAGE}-${MACHINE}-rofs.its tmp.its
	sed -i -- 's/NUVOTON_RO_OFFSET_IN_FIT/580000/g' tmp.its
	mv tmp.its ${DEPLOY_DIR_IMAGE}/fitImage-its-${INITRAMFS_IMAGE}-${MACHINE}-rofs.its
	uboot-mkimage -f "${DEPLOY_DIR_IMAGE}/fitImage-its-${INITRAMFS_IMAGE}-${MACHINE}-rofs.its" \
					-k "${DEPLOY_DIR_IMAGE}/uboot_fitkey" \
					"${DEPLOY_DIR_IMAGE}/${FLASH_FIT_KERNEL_RO}"


}

make_tar_of_nuvoton_images () {
       type=$1
       shift
       extra_files="$@"

       # Create the tar archive
       tar -h -cvf ${IMGDEPLOYDIR}/${IMAGE_NAME}.$type.mtd.tar \
               image-u-boot image-u-boot.sig image-rwfs image-rwfs.sig \
               MANIFEST MANIFEST.sig publickey publickey.sig \
               image-kernel-rofs \
               $extra_files

       cd ${IMGDEPLOYDIR}
       ln -sf ${IMAGE_NAME}.$type.mtd.tar ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.$type.mtd.tar
}

do_generate_ubi_tar_append () {

	cd ${S}/ubi
	ln -sf ${DEPLOY_DIR_IMAGE}/${FLASH_FIT_KERNEL_RO} image-kernel-rofs
	make_signatures image-kernel-rofs
	make_tar_of_nuvoton_images nuvoton ${signature_files}
}

do_restore_uboot () {

	# rename the plan u-boot to be the default (for the nex builds) 
	cp ${UBOOT_BIN}.plan ${UBOOT_BIN}
}

do_generate_static_prepend () {

    bb.build.exec_func("do_prepare_merged_bb_uboot", d)
}

do_generate_static_append () {
    _append_image(os.path.join(d.getVar('DEPLOY_DIR_IMAGE', True),d.getVar('FLASH_FIT_KERNEL_RO', True)),
                  int(d.getVar('FLASH_KERNEL_OFFSET', True)),
                  int(d.getVar('FLASH_RWFS_OFFSET', True)))

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
