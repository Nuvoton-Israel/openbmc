do_generate_static[depends] += "u-boot-fw-utils-nuvoton:do_populate_sysroot"
do_generate_static[depends] += "u-boot-nuvoton:do_populate_sysroot"
do_generate_static[depends] += "npcm750-bootblock:do_deploy"
do_generate_static[depends] += "npcm7xx-signit-native:do_populate_sysroot"
do_generate_static[depends] += "npcm7xx-bingo-native:do_populate_sysroot"
do_generate_static[depends] += "npcm7xx-uut-native:do_populate_sysroot"
do_generate_static[depends] += "npcm7xx-igps-native:do_populate_sysroot"

inherit npcm7xx-image

FLASH_UBOOT_OFFSET = "0"
FLASH_KERNEL_OFFSET = "2048"
FLASH_UBI_OFFSET = "${FLASH_KERNEL_OFFSET}"
FLASH_ROFS_OFFSET = "7680"
FLASH_RWFS_OFFSET = "30720"

# UBI volume sizes in KB unless otherwise noted.
FLASH_UBI_RWFS_SIZE = "6144"
FLASH_UBI_RWFS_TXT_SIZE = "6MiB"

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
	# by do_generate_static (after will be restored by o_npcm7xx_bb_uboot_end)  
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

do_generate_static_append () {

    bb.build.exec_func("do_restore_uboot", d)
}

