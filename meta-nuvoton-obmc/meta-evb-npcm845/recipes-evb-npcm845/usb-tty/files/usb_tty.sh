#!/bin/bash
#
# Configure USB gadget as ACM serial (TTY) interface.
#

GADGET_NAME="usb_tty"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"

# Ensure configfs is mounted
if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config
fi

# Detect UDC name based on kernel version
# OTG4 is used for this gadget on NPCM845
MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
if [ "${MAJOR_VERSION}" -ge 6 ]; then
    UDC_NAME="ci_hdrc.4"
else
    UDC_NAME="f0834000.udc"
fi
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# Skip if gadget already configured
if [ -d "${GADGET_DIR}" ]; then
    echo "USB TTY gadget already configured, skipping."
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
echo "BMC USB TTY Gadget"    > strings/0x409/product
echo "NPCM845TTY001"         > strings/0x409/serialnumber

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "ACM Serial"            > configs/c.1/strings/0x409/configuration
echo 120                     > configs/c.1/MaxPower

# ACM Function
mkdir -p functions/acm.usb0

# Link function to configuration
ln -s functions/acm.usb0 configs/c.1/

# Bind to UDC
echo "${UDC_NAME}" > UDC

echo "USB TTY gadget started (UDC: ${UDC_NAME})"

# ── Wait for ttyGS0 to appear ────────────────────────────────────────────────
RETRY=0
while [ ${RETRY} -lt 10 ]; do
    [ -e /dev/ttyGS0 ] && break
    sleep 1
    RETRY=$(( RETRY + 1 ))
done

if [ ! -e /dev/ttyGS0 ]; then
    echo "WARNING: /dev/ttyGS0 did not appear after 10s" >&2
    exit 1
fi

# ── Start getty on ttyGS0 ────────────────────────────────────────────────────
# Uses the standard systemd serial-getty template so that BMC console
# output is forwarded to the USB TTY (equivalent to:
#   /sbin/getty -L 115200 ttyGS0 vt100)
systemctl start serial-getty@ttyGS0.service
echo "getty started on ttyGS0"

exit 0
