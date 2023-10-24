NUVOTON_FLASH_PCIMBOX1 = "0xF0848000"
NUVOTON_FLASH_PCIMBOX2 = "0xF0868000"
NUVOTON_FLASH_LPC     = "0xC0008000"

#PACKAGECONFIG:append:evb-npcm845 = " nuvoton-lpc static-bmc reboot-update"
PACKAGECONFIG:append:evb-npcm845 = " nuvoton-p2a-mbox static-bmc reboot-update"

IMAGE_PATH = "/run/initramfs/image-bmc"
EXTRA_OEMESON:append:evb-npcm845 = " -Dstatic-handler-staged-name=${IMAGE_PATH}"
IPMI_FLASH_BMC_ADDRESS:evb-npcm845 = "${NUVOTON_FLASH_PCIMBOX1}"

# NPCM8xx is using 0x0850 as PCI device-id.
NUVOTON_PCI_DID = "2128"
EXTRA_OEMESON:append:evb-npcm845 = " -Dnuvoton-pci-did=${NUVOTON_PCI_DID}"
