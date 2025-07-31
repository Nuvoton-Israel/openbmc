KSRC = "git://github.com/Nuvoton-Israel/linux;protocol=https;branch=${KBRANCH}"
KBRANCH = "NPCM-6.6-OpenBMC"
LINUX_VERSION = "6.6.62"
SRCREV = "b93b3bcbf78de9b56307c67ae7b167ed526cdba6"

require ../../../../meta-nuvoton/recipes-kernel/linux/linux-nuvoton.inc

SRC_URI:append:nuvoton = " file://enable-emc.cfg"
SRC_URI:append:nuvoton:df-obmc-static-norootfs = " file://enable-spinor-ubifs.cfg"

# AF_MCTP core patches
SRC_URI:append:nuvoton = " file://0001-mctp-avoid-confusion-over-local-peer-dest-source-add.patch"
SRC_URI:append:nuvoton = " file://0002-mctp-make-key-lookups-match-the-ANY-address-on-eithe.patch"
SRC_URI:append:nuvoton = " file://0003-mctp-serial-use-netif_receive_skb-instead-of-netif_r.patch"

# New Arch VDMX/VDMA driver
# SRC_URI:append:nuvoton = " file://2222-driver-misc-add-nuvoton-vdmx-vdma-driver.patch"
# SRC_URI:append:nuvoton = " file://2223-net-mctp-Support-mctp-over-pcie-vdm.patch"

# Patch for Intel MCTP over PCIe VDM support
# SRC_URI:append:nuvoton = " file://0015-driver-misc-nuvoton-vdm-support-openbmc-libmctp.patch"

# Patch for Legacy UDC driver
# SRC_URI:append:nuvoton = " file://0001-usb-gadget-udc-add-NPCM-UDC-support.patch"
# SRC_URI:append:nuvoton = " file://enable-usb-legacy.cfg"
