#KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KSRC = "git://github.com/YHYANG2/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-6.12-OpenBMC"
LINUX_VERSION = "6.12.17"
SRCREV = "7fe003d6ad08b2295ad8f71c440ac3e2a7ca7826"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"

# AF_MCTP core patches
#SRC_URI:append:nuvoton = " file://0001-mctp-avoid-confusion-over-local-peer-dest-source-add.patch"
#SRC_URI:append:nuvoton = " file://0002-mctp-make-key-lookups-match-the-ANY-address-on-eithe.patch"
#SRC_URI:append:nuvoton = " file://0003-mctp-serial-use-netif_receive_skb-instead-of-netif_r.patch"

# AF_MCTP over USB patches
#SRC_URI:append:nuvoton = " file://0001-usb-Add-generic-MCTP-include.patch"
#SRC_URI:append:nuvoton = " file://0002-net-mctp-Add-MCTP-USB-transport-driver.patch"
#SRC_URI:append:nuvoton = " file://0003-usb-gadget-Add-MCTP-USB-function.patch"
#SRC_URI:append:nuvoton = " file://0004-usb-gadget-mctp-defer-tx-to-batch.patch"
#SRC_URI:append:nuvoton = " file://0005-driver-usb-f_mctp-add-high-speed-support.patch"
#SRC_URI:append:nuvoton = " file://0006-driver-mctp-usb-fix-rx-issue.patch"
#SRC_URI:append:nuvoton = " file://0007-driver-mctp-usb-set-max-mtu-to-255.patch"

# New Arch VDMX/VDMA driver
# SRC_URI:append:nuvoton = " file://2222-driver-misc-add-nuvoton-vdmx-vdma-driver.patch"
# SRC_URI:append:nuvoton = " file://2223-net-mctp-Support-mctp-over-pcie-vdm.patch"

# Patch for Intel MCTP over PCIe VDM support
# SRC_URI:append:nuvoton = " file://0015-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"

# Patch for Legacy UDC driver
# SRC_URI:append:nuvoton = " file://0001-usb-gadget-udc-add-NPCM-UDC-support.patch"
# SRC_URI:append:nuvoton = " file://enable-usb-legacy.cfg"
