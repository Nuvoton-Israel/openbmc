#!/bin/bash
#
# Configure USB gadget as Mass Storage interface using eMMC.
#

GADGET_NAME="mmc-storage"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
MMC_DEVICE="/dev/mmcblk0"

# Ensure configfs is mounted
if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config
fi

# Detect UDC name based on kernel version
# OTG1 is used for this gadget on NPCM845
MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
if [ "${MAJOR_VERSION}" -ge 6 ]; then
    UDC_NAME="ci_hdrc.1"
else
    UDC_NAME="f0831000.udc"
fi
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# Skip if gadget already configured
if [ -d "${GADGET_DIR}" ]; then
    echo "USB MMC Storage gadget already configured, skipping."
    exit 0
fi

# Setup Gadget
mkdir -p "${GADGET_DIR}"
cd "${GADGET_DIR}" || exit 1

# USB Device Descriptor
# 0x1d6b / 0x0104 : Linux Foundation - Multifunction Composite Gadget
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0200" > bcdUSB
echo "0x0100" > bcdDevice

# String Descriptors
mkdir -p strings/0x409
echo "Nuvoton"               > strings/0x409/manufacturer
echo "MMC Storage Device"    > strings/0x409/product
echo "NPCM845MMC001"         > strings/0x409/serialnumber

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "Mass Storage"          > configs/c.1/strings/0x409/configuration
echo 120                     > configs/c.1/MaxPower

# Mass Storage Function
mkdir -p functions/mass_storage.usb0
echo 1 > functions/mass_storage.usb0/lun.0/removable
echo 0 > functions/mass_storage.usb0/lun.0/ro
echo 0 > functions/mass_storage.usb0/lun.0/cdrom
echo "${MMC_DEVICE}" > functions/mass_storage.usb0/lun.0/file

# Link function to configuration
ln -s functions/mass_storage.usb0 configs/c.1/

# Bind to UDC
echo "${UDC_NAME}" > UDC

echo "USB MMC Storage gadget started (UDC: ${UDC_NAME}, Device: ${MMC_DEVICE})"

exit 0
