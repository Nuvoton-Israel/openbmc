# obmc-ramboot: build image-ramboot, one FIT image with the kernel, the device
# tree and a ramdisk made of the OpenBMC initramfs plus image-rofs (stored as
# /image-rofs), to boot OpenBMC from RAM without reading flash or eMMC.
#
# The initramfs (obmc-init.sh) moves /image-rofs to /run/image-rofs and
# loop-mounts it as the read-only root; the overlay-filesystem-in-ram kernel
# argument keeps the read-write layer in tmpfs, so nothing is saved.
#
# In U-Boot, with the file on a TFTP server:
#   setenv ipaddr <board IP>; setenv serverip <TFTP server IP>
#   tftp <RAM address> image-ramboot
#   setenv bootargs earlycon=${earlycon} console=${console} overlay-filesystem-in-ram
#   bootm <RAM address>
# Pick a RAM address the kernel and the ramdisk do not overwrite while
# booting (above UBOOT_LOADADDRESS plus a few tens of MiB).
#
# Only built with the SPI-NOR flash image types (mtd-static), which are the
# ones that build the squashfs image-rofs. Machine values come from
# KERNEL_IMAGETYPE, KERNEL_DEVICETREE (first entry), UBOOT_LOADADDRESS,
# UBOOT_ENTRYPOINT, INITRAMFS_IMAGE and INITRAMFS_FSTYPES.

DEPENDS:append = " u-boot-tools-native dtc-native"

RAMBOOT_DTB = "${@os.path.basename(d.getVar('KERNEL_DEVICETREE').split()[0])}"
RAMBOOT_INITRAMFS = "${INITRAMFS_IMAGE}-${MACHINE}.${INITRAMFS_FSTYPES}"

do_generate_ramboot() {
    rm -rf root
    mkdir -p root
    cp -L ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMAGE_BASETYPE} root/image-rofs
    # The kernel unpacks every cpio archive in the initrd.
    (cd root && echo image-rofs | cpio -o -H newc --owner=0:0 --quiet) > rofs.cpio
    cat ${DEPLOY_DIR_IMAGE}/${RAMBOOT_INITRAMFS} rofs.cpio > initrd.cpio
    rm -rf root rofs.cpio
    gzip -9 -n -c ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} > kernel.gz
    cp -L ${DEPLOY_DIR_IMAGE}/${RAMBOOT_DTB} board.dtb

    cat > ramboot.its <<ITS
/dts-v1/;
/ {
    description = "OpenBMC RAM boot image for ${MACHINE}: kernel, device tree, initramfs with image-rofs";
    #address-cells = <1>;
    images {
        kernel-1 {
            description = "Linux kernel";
            data = /incbin/("kernel.gz");
            type = "kernel";
            arch = "arm64";
            os = "linux";
            compression = "gzip";
            load = <${UBOOT_LOADADDRESS}>;
            entry = <${UBOOT_ENTRYPOINT}>;
            hash-1 { algo = "sha256"; };
        };
        fdt-1 {
            description = "${RAMBOOT_DTB}";
            data = /incbin/("board.dtb");
            type = "flat_dt";
            arch = "arm64";
            compression = "none";
            hash-1 { algo = "sha256"; };
        };
        ramdisk-1 {
            description = "${INITRAMFS_IMAGE} + /image-rofs";
            data = /incbin/("initrd.cpio");
            type = "ramdisk";
            arch = "arm64";
            os = "linux";
            compression = "none";
            hash-1 { algo = "sha256"; };
        };
    };
    configurations {
        default = "conf-1";
        conf-1 {
            description = "Boot OpenBMC from RAM";
            kernel = "kernel-1";
            fdt = "fdt-1";
            ramdisk = "ramdisk-1";
        };
    };
};
ITS
    mkimage -f ramboot.its ${IMGDEPLOYDIR}/${IMAGE_NAME}.ramboot.itb
    rm -f kernel.gz board.dtb initrd.cpio
    ln -sf ${IMAGE_NAME}.ramboot.itb ${IMGDEPLOYDIR}/image-ramboot
}
do_generate_ramboot[dirs] = "${WORKDIR}/ramboot"
do_generate_ramboot[cleandirs] = "${WORKDIR}/ramboot"
do_generate_ramboot[depends] += " \
    virtual/kernel:do_deploy \
    ${INITRAMFS_IMAGE}:do_image_complete \
"

python () {
    if 'mtd-static' in d.getVar('IMAGE_FSTYPES').split():
        basetype = d.getVar('IMAGE_BASETYPE').replace('-', '_')
        bb.build.addtask('do_generate_ramboot', 'do_image_complete',
                         'do_image_' + basetype, d)
}
