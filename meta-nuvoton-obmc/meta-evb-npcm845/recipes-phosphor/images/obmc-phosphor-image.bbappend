IMAGE_INSTALL:append = " tpm2-tools tpm2-tss libtss2 libtss2-mu libtss2-tcti-device tpm2-abrmd"
IMAGE_INSTALL:append = " usb-emmc-storage"
IMAGE_INSTALL:append = " usb-network-rndis"
IMAGE_INSTALL:append = " cpfw"
IMAGE_INSTALL:append = " dhrystone"
IMAGE_INSTALL:append = " ent"
IMAGE_INSTALL:append = " rw-perf"
IMAGE_INSTALL:append = " phosphor-ecc"
IMAGE_INSTALL:append = " i3c-tools"
IMAGE_INSTALL:append = " phosphor-ipmi-blobs"
IMAGE_INSTALL:append = " phosphor-image-signing"
IMAGE_INSTALL:append = " program-vbios"
IMAGE_INSTALL:append = " program-edid"
IMAGE_INSTALL:append = " cerberus-utility"
IMAGE_INSTALL:append = " systemd-analyze"
IMAGE_INSTALL:append = " pldm"
IMAGE_INSTALL:append = " mctp"
IMAGE_INSTALL:append = " usb-tty"
#IMAGE_INSTALL:append = " estoraged"
#IMAGE_INSTALL:append = " cryptsetup"
IMAGE_INSTALL:append = " npcm400-fw-tool"
IMAGE_INSTALL:append = " automation-test-tools"
IMAGE_INSTALL:append = " v4l-utils"
IMAGE_INSTALL:append = " usb-network-ecm"

# Disable login shell auto-logout on idle
DEFAULT_TTY_IDLE_TIMEOUT = "0"

# curl for exercising the Composite EAT Redfish API on target
IMAGE_INSTALL:append:df-composite-eat = " curl"

# OBMF-ICP driver-level stress test (obmf-stress -h)
IMAGE_INSTALL:append:df-obmf = " obmf-stress"

# Redfish Satellite BMC: ECM link towards the Aggregator BMC.
# usb-network-ecm is dropped because it uses the same 192.168.7.1/24 address;
# usb-emmc-storage is dropped to keep the USB device controllers free for the satellite link.
# usb-network-rndis and obmc-ikvm (HID gadget) are not used on a satellite.
IMAGE_INSTALL:append:df-satellite = " usb-satellite-link"
IMAGE_INSTALL:remove:df-satellite = "usb-network-ecm usb-emmc-storage usb-network-rndis"
IMAGE_FEATURES:remove:df-satellite = "obmc-ikvm"
