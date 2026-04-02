#!/bin/bash
#
# Configure USB gadget as RNDIS network interface.
#
# Network layout:
#   BMC  (${IFACE}): 192.168.8.1/24
#
# Compatible with: Windows, Linux, macOS
#

GADGET_NAME="rndis"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
IFACE="rndis0"

# Default Network Configuration
BMC_IP="192.168.8.1"
BMC_PREFIX="24"

# Fixed MAC addresses — required for stable host-side network profiles
# Host-side MAC must be unicast (LSB of first byte = 0)
BMC_MAC="02:00:11:22:33:45"   # BMC side (dev_addr)
HOST_MAC="02:00:55:66:77:89"  # host side (host_addr)

# Ensure configfs is mounted
if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config
fi

# Detect UDC name based on kernel version
MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
if [ "${MAJOR_VERSION}" -ge 6 ]; then
    UDC_NAME="ci_hdrc.2"
else
    UDC_NAME="f0832000.udc"
fi
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# Skip if gadget already configured
if [ -d "${GADGET_DIR}" ]; then
    echo "USB RNDIS gadget already configured, skipping."
    # Ensure interface is up and IP is assigned
    ip addr show dev "${IFACE}" | grep -q "${BMC_IP}" || \
        ip addr add "${BMC_IP}/${BMC_PREFIX}" dev "${IFACE}" 2>/dev/null || true
    ip link set "${IFACE}" up 2>/dev/null || true
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
echo "BMC USB Network RNDIS" > strings/0x409/product
echo "NPCM845RNDIS001"       > strings/0x409/serialnumber

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "RNDIS"                 > configs/c.1/strings/0x409/configuration
echo 100                     > configs/c.1/MaxPower

# RNDIS Function
# NOTE: The kernel names RNDIS interfaces usb0, usb1... regardless of the
# function directory name.  Interface renaming to "${IFACE}" is handled
# by the systemd .link file (10-bmc-usb-rndis.link) matching by MAC address.
mkdir -p functions/rndis.usb0
echo "${BMC_MAC}"  > functions/rndis.usb0/dev_addr
echo "${HOST_MAC}" > functions/rndis.usb0/host_addr

# Windows compatibility settings
echo ef > functions/rndis.usb0/class
echo 04 > functions/rndis.usb0/subclass
echo 01 > functions/rndis.usb0/protocol

# Link function to configuration
ln -s "functions/rndis.usb0" configs/c.1/

# Bind to UDC
echo "${UDC_NAME}" > UDC

echo "USB RNDIS gadget started (UDC: ${UDC_NAME})"

# Wait for kernel to create the gadget net interface (usb0, usb1, …).
# Scan ALL net interfaces by MAC — handles the case where udev .link already
# renamed usb0 to ${IFACE} before this script checks.
KERNEL_IFACE=""
RETRY=0
while [ ${RETRY} -lt 20 ]; do
    for iface in /sys/class/net/*; do
        [ -e "${iface}/address" ] || continue
        mac=$(cat "${iface}/address")
        if [ "${mac}" = "${BMC_MAC}" ]; then
            KERNEL_IFACE=$(basename "${iface}")
            break 2
        fi
    done
    sleep 1
    RETRY=$(( RETRY + 1 ))
done

if [ -z "${KERNEL_IFACE}" ]; then
    echo "ERROR: RNDIS gadget interface with MAC ${BMC_MAC} did not appear after 20s" >&2
    exit 1
fi

echo "RNDIS gadget interface appeared as: ${KERNEL_IFACE}"

# Rename to the stable name (if not already named correctly)
if [ "${KERNEL_IFACE}" != "${IFACE}" ]; then
    ip link set "${KERNEL_IFACE}" down 2>/dev/null || true
    ip link set "${KERNEL_IFACE}" name "${IFACE}"
    echo "Renamed ${KERNEL_IFACE} -> ${IFACE}"
fi

# IP assignment is handled by systemd-networkd via 00-bmc-usb0-rndis.network
echo "Interface ${IFACE} ready — IP will be assigned by systemd-networkd"

exit 0
