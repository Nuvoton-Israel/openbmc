do_generate_static[depends] += "npcm7xx-flashtool-native:do_populate_sysroot"
do_generate_static[depends] += "npcm750-bootblock:do_deploy"

FLASH_BOOTBLOCK_OFFSET = "0"
FLASH_UBOOT_OFFSET = "52"
FLASH_KERNEL_OFFSET = "2048"
FLASH_UBI_OFFSET = "${FLASH_KERNEL_OFFSET}"
FLASH_ROFS_OFFSET = "7680"
FLASH_RWFS_OFFSET = "30720"

# UBI volume sizes in KB unless otherwise noted.
FLASH_UBI_RWFS_SIZE = "6144"
FLASH_UBI_RWFS_TXT_SIZE = "6MiB"

# EVB NPCM750 u-boot, contains bootblock and uboot
UBOOT_IMAGE_NAME = "evb-npcm750.u-boot"

OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-host"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-kcs"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-ipmi-net"
OBMC_IMAGE_EXTRA_INSTALL_append = " phosphor-cooling-type"

IMAGE_INSTALL_append = " bmcweb \
                         obmc-ikvm \
                         phosphor-webui \
                         phosphor-ipmi-host \
                         lmsensors-fancontrol \
                         lmsensors-pwmconfig \
                         lmsensors-sensord \
                         lmsensors-sensors \
                         iperf2 \
                       "

add_flash_pbl() {
	BOOTBLOCK="bootblock.bin"
	FULLBOOTBLOCK="${BOOTBLOCK}.full"

	create_image --bootblock ${DEPLOY_DIR_IMAGE}/${BOOTBLOCK} \
		${IMGDEPLOYDIR}/${FULLBOOTBLOCK}
	dd if=${IMGDEPLOYDIR}/${FULLBOOTBLOCK} \
		of=${IMGDEPLOYDIR}/${UBOOT_IMAGE_NAME} \
		bs=1k conv=notrunc seek=${FLASH_BOOTBLOCK_OFFSET}
	dd if=${IMGDEPLOYDIR}/${FULLBOOTBLOCK} \
		of=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd \
		bs=1k conv=notrunc seek=${FLASH_BOOTBLOCK_OFFSET}
}

add_flash_uboot() {
	UBOOT="u-boot.${UBOOT_SUFFIX}"
	FULLUBOOT="${UBOOT}.full"

	create_image --uboot ${DEPLOY_DIR_IMAGE}/${UBOOT} \
		${IMGDEPLOYDIR}/${FULLUBOOT}
	dd if=${IMGDEPLOYDIR}/${FULLUBOOT} \
		of=${IMGDEPLOYDIR}/${UBOOT_IMAGE_NAME} \
		bs=1k conv=notrunc seek=${FLASH_UBOOT_OFFSET}
	dd if=${IMGDEPLOYDIR}/${FULLUBOOT} \
		of=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd \
		bs=1k conv=notrunc seek=${FLASH_UBOOT_OFFSET}
}

add_flash_linux() {
	dd bs=1k conv=notrunc seek=${FLASH_KERNEL_OFFSET} \
		if=${DEPLOY_DIR_IMAGE}/${FLASH_KERNEL_IMAGE} \
		of=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd

	dd bs=1k conv=notrunc seek=${FLASH_ROFS_OFFSET} \
		if=${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMAGE_BASETYPE} \
		of=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd

	dd bs=1k conv=notrunc seek=${FLASH_RWFS_OFFSET} \
		if=rwfs.${OVERLAY_BASETYPE} \
		of=${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd
}

do_generate_static() {
	# Assemble the flash image
	mk_nor_image ${IMGDEPLOYDIR}/${IMAGE_NAME}.static.mtd ${FLASH_SIZE}
	add_flash_pbl
	add_flash_uboot
	add_flash_linux

	# File needed for generating non-standard legacy links below
	cp rwfs.${OVERLAY_BASETYPE} ${IMGDEPLOYDIR}/rwfs.${OVERLAY_BASETYPE}

	cd ${IMGDEPLOYDIR}
	ln -sf ${IMAGE_NAME}.static.mtd ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.static.mtd

	# Maintain non-standard legacy links
	ln -sf ${IMAGE_NAME}.static.mtd ${IMGDEPLOYDIR}/flash-${MACHINE}
	ln -sf ${IMAGE_NAME}.static.mtd ${IMGDEPLOYDIR}/image-bmc
	ln -sf ${UBOOT_IMAGE_NAME} ${IMGDEPLOYDIR}/image-u-boot
	ln -sf ${FLASH_KERNEL_IMAGE} ${IMGDEPLOYDIR}/image-kernel
	ln -sf ${IMAGE_LINK_NAME}.${IMAGE_BASETYPE} ${IMGDEPLOYDIR}/image-rofs
	ln -sf rwfs.${OVERLAY_BASETYPE} ${IMGDEPLOYDIR}/image-rwfs
}
