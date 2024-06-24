NUVOTON_FLASH_PCIMBOX1 = "0xF0848000"
NUVOTON_FLASH_PCIMBOX2 = "0xF0868000"
NUVOTON_FLASH_LPC     = "0xC0008000"

#PACKAGECONFIG:append:scm-npcm845 = " nuvoton-lpc static-bmc reboot-update"
PACKAGECONFIG:append = " nuvoton-p2a-mbox static-bmc reboot-update"

IMAGE_PATH = "/run/initramfs/image-bmc"
EXTRA_OEMESON:append = " -Dstatic-handler-staged-name=${IMAGE_PATH}"
IPMI_FLASH_BMC_ADDRESS = "${NUVOTON_FLASH_PCIMBOX1}"
