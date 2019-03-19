SRCREV = "457e879dd929e01f577ec2184670e1bedd27c69d"

UBOOT_SIGN_ENABLE = "1"

do_deploy_dtb_prepend () {
	cp ${B}/u-boot.bin ${B}/${UBOOT_NODTB_BINARY}
}