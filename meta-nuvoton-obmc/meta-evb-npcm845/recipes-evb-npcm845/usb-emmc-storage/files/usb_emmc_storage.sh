#!/bin/sh
#
# usb_emmc_storage.sh
# Configure USB gadget to expose eMMC as USB Mass Storage device.
# Compatible with: Linux (OpenBMC host), Windows, Red Hat / RHEL / Fedora hosts.
#
# Red Hat compatibility notes:
#   - configfs must be mounted before running this script
#   - inquiry_string must be set for SCSI device identification
#   - nofua=1 avoids FUA command issues on RHEL's usb_storage driver
#   - bcdDevice / bcdUSB / serial are required for proper udev enumeration
#   - removable=0 prevents RHEL treating the device as removable media (avoids mount failures)

set -e

GADGET_NAME="mmc-storage"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
MMC_DEVICE="/dev/mmcblk0"

# ── Validate eMMC device exists ──────────────────────────────────────────────
if [ ! -b "${MMC_DEVICE}" ]; then
    echo "ERROR: Block device ${MMC_DEVICE} not found." >&2
    exit 1
fi

# ── Ensure configfs is mounted ───────────────────────────────────────────────
if ! mountpoint -q /sys/kernel/config; then
    mount -t configfs none /sys/kernel/config
fi

# ── Detect UDC name based on kernel version ──────────────────────────────────
# Kernel < 6.x : f0831000.udc (legacy NPCM UDC driver name)
# Kernel >= 6.x : ci_hdrc.1   (ChipIdea UDC driver)
MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
if [ "${MAJOR_VERSION}" -ge 6 ]; then
    UDC_NAME="ci_hdrc.1"
else
    UDC_NAME="f0831000.udc"
fi

# Allow override via environment variable (useful for testing)
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# Validate UDC is available
if [ ! -d "/sys/class/udc/${UDC_NAME}" ]; then
    echo "WARNING: UDC '${UDC_NAME}' not found in /sys/class/udc/." >&2
    echo "Available UDCs: $(ls /sys/class/udc/ 2>/dev/null || echo 'none')" >&2
fi

# ── Cleanup existing gadget if already configured ────────────────────────────
if [ -d "${GADGET_DIR}" ]; then
    echo "" > "${GADGET_DIR}/UDC" 2>/dev/null || true
    rm -f "${GADGET_DIR}/configs/c.1/mass_storage.usb0" 2>/dev/null || true
    rmdir "${GADGET_DIR}/configs/c.1/strings/0x409" 2>/dev/null || true
    rmdir "${GADGET_DIR}/configs/c.1" 2>/dev/null || true
    rmdir "${GADGET_DIR}/functions/mass_storage.usb0" 2>/dev/null || true
    rmdir "${GADGET_DIR}/strings/0x409" 2>/dev/null || true
    rmdir "${GADGET_DIR}" 2>/dev/null || true
fi

# ── Create gadget directory ──────────────────────────────────────────────────
mkdir -p "${GADGET_DIR}"
cd "${GADGET_DIR}"

# ── USB Device Descriptor ────────────────────────────────────────────────────
# Vendor: 0x1d6b  Linux Foundation
# Product: 0x0104 Multifunction Composite Gadget
# bcdUSB: 0x0200 = USB 2.0 (required for RHEL udev to enumerate correctly)
# bcdDevice: 0x0100 = Device version 1.0
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0200" > bcdUSB
echo "0x0100" > bcdDevice

# ── String Descriptors (English) ─────────────────────────────────────────────
# RHEL udev uses these strings for device naming via udev rules.
# serial is used as unique device identifier — RHEL requires it for stable /dev/disk/by-id/ links.
mkdir -p strings/0x409
echo "Nuvoton"             > strings/0x409/manufacturer
echo "MMC Storage Device"  > strings/0x409/product
echo "NPCM845EMMC0001"     > strings/0x409/serialnumber

# ── Configuration Descriptor ─────────────────────────────────────────────────
mkdir -p configs/c.1/strings/0x409
echo "config 1"            > configs/c.1/strings/0x409/configuration
echo 120                   > configs/c.1/MaxPower    # 120 x 2mA = 240mA

# ── Mass Storage Function ─────────────────────────────────────────────────────
mkdir -p functions/mass_storage.usb0

# LUN 0 — eMMC block device
# removable=0 : RHEL treats removable=1 as optical/removable media → may skip automount
# ro=0        : read-write access
# cdrom=0     : not a CD-ROM device
# nofua=1     : disable Force Unit Access (FUA) — RHEL usb_storage driver compatibility fix
# inquiry_string: SCSI Inquiry response (Vendor[8] + Product[16] + Rev[4])
#                 RHEL uses this for device identification in /dev/disk/by-id/
echo 0              > functions/mass_storage.usb0/lun.0/removable
echo 0              > functions/mass_storage.usb0/lun.0/ro
echo 0              > functions/mass_storage.usb0/lun.0/cdrom
echo 1              > functions/mass_storage.usb0/lun.0/nofua
echo "Nuvoton MMC Storage 0001" \
                    > functions/mass_storage.usb0/lun.0/inquiry_string
echo "${MMC_DEVICE}" > functions/mass_storage.usb0/lun.0/file

# ── Link function to configuration ───────────────────────────────────────────
ln -s "$(pwd)/functions/mass_storage.usb0" configs/c.1/

# ── Bind to UDC ──────────────────────────────────────────────────────────────
echo "${UDC_NAME}" > UDC

echo "USB MMC Storage gadget started successfully."
echo "  UDC      : ${UDC_NAME}"
echo "  Device   : ${MMC_DEVICE}"
echo "  Gadget   : ${GADGET_DIR}"
exit 0
