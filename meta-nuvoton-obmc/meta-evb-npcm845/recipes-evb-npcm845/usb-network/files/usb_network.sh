#!/bin/sh
#
# usb_network.sh
# Configure USB gadget as CDC ECM network interface.
#
# Compatible with: Red Hat / RHEL / Fedora (uses cdc_ether driver, auto-detected)
#                  Linux (standard CDC ECM)
#                  macOS (standard CDC ECM)
#
# Unit identity is determined by two GPIO strap pins at boot:
#
#   GPIO12  GPIO13  Unit   BMC IP          Host IP         BMC MAC (dev_addr)   Host MAC (host_addr)
#   ------  ------  ----   ----------      ----------      -------------------  --------------------
#     0       0      A     192.168.7.2     192.168.7.1     02:00:11:22:33:44    02:00:55:66:77:88
#     0       1      B     192.168.8.2     192.168.8.1     02:00:11:22:33:45    02:00:55:66:77:89
#     1       0      C     192.168.9.2     192.168.9.1     02:00:11:22:33:46    02:00:55:66:77:8a
#     1       1      D     192.168.10.2    192.168.10.1    02:00:11:22:33:47    02:00:55:66:77:8b
#
# Note: Host IP must be configured manually on the RHEL host side (no DHCP server).
#
# SSH to BMC from RHEL host (example for unit A):
#   ssh root@192.168.7.2

GADGET_NAME="g1"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
BMC_PREFIX="24"
IFACE="usb0"

# ── Read GPIO strap pins to determine BMC unit identity ──────────────────────
# Uses the sysfs GPIO interface. If gpioget (libgpiod) is available it is
# preferred; otherwise /sys/class/gpio export is used as a fallback.
read_gpio() {
    # $1 = GPIO number (e.g. 8 or 15)
    local gpio="$1"

    # Method 1: gpioget (libgpiod) — preferred, no side-effects
    if command -v gpioget > /dev/null 2>&1; then
        gpioget gpiochip0 "${gpio}" 2>/dev/null
        return
    fi

    # Method 2: sysfs export/unexport
    local sysfs_gpio="/sys/class/gpio/gpio${gpio}"
    if [ ! -d "${sysfs_gpio}" ]; then
        echo "${gpio}" > /sys/class/gpio/export 2>/dev/null || true
        sleep 0.05
    fi
    if [ -f "${sysfs_gpio}/value" ]; then
        cat "${sysfs_gpio}/value"
    else
        echo "0"  # safe default
    fi
}

GPIO12=$(read_gpio 12)
GPIO13=$(read_gpio 13)

# Normalize to exactly "0" or "1"
GPIO12=$(echo "${GPIO12}" | tr -d '[:space:]')
GPIO13=$(echo "${GPIO13}" | tr -d '[:space:]')

echo "GPIO strap: GPIO12=${GPIO12} GPIO13=${GPIO13}"

# ── Select per-unit network parameters ───────────────────────────────────────
if   [ "${GPIO12}" = "0" ] && [ "${GPIO13}" = "0" ]; then
    UNIT="A"
    BMC_IP="192.168.7.2"
    HOST_IP="192.168.7.1"
    BMC_MAC="02:00:11:22:33:44"
    HOST_MAC="02:00:55:66:77:88"
elif [ "${GPIO12}" = "0" ] && [ "${GPIO13}" = "1" ]; then
    UNIT="B"
    BMC_IP="192.168.8.2"
    HOST_IP="192.168.8.1"
    BMC_MAC="02:00:11:22:33:45"
    HOST_MAC="02:00:55:66:77:89"
elif [ "${GPIO12}" = "1" ] && [ "${GPIO13}" = "0" ]; then
    UNIT="C"
    BMC_IP="192.168.9.2"
    HOST_IP="192.168.9.1"
    BMC_MAC="02:00:11:22:33:46"
    HOST_MAC="02:00:55:66:77:8a"
elif [ "${GPIO12}" = "1" ] && [ "${GPIO13}" = "1" ]; then
    UNIT="D"
    BMC_IP="192.168.10.2"
    HOST_IP="192.168.10.1"
    BMC_MAC="02:00:11:22:33:47"
    HOST_MAC="02:00:55:66:77:8b"
else
    echo "ERROR: unexpected GPIO values (GPIO12=${GPIO12}, GPIO13=${GPIO13}), defaulting to unit A" >&2
    UNIT="A"
    BMC_IP="192.168.7.2"
    HOST_IP="192.168.7.1"
    BMC_MAC="02:00:11:22:33:44"
    HOST_MAC="02:00:55:66:77:88"
fi

echo "BMC unit: ${UNIT}  BMC IP: ${BMC_IP}  Host IP: ${HOST_IP}"
echo "BMC MAC: ${BMC_MAC}  Host MAC: ${HOST_MAC}"

# ── Ensure configfs is mounted ───────────────────────────────────────────────
if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config
fi

# ── Detect UDC name based on kernel version ──────────────────────────────────
MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
if [ "${MAJOR_VERSION}" -ge 6 ]; then
    UDC_NAME="ci_hdrc.2"
else
    UDC_NAME="f0832000.udc"
fi
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# ── Skip if gadget already configured ────────────────────────────────────────
if [ -d "${GADGET_DIR}" ]; then
    echo "USB network gadget already configured, skipping."
    # Still ensure IP is assigned
    ip addr show dev "${IFACE}" | grep -q "${BMC_IP}" || \
        ip addr add "${BMC_IP}/${BMC_PREFIX}" dev "${IFACE}" 2>/dev/null || true
    ip link set "${IFACE}" up 2>/dev/null || true
    exit 0
fi

mkdir -p "${GADGET_DIR}"
cd "${GADGET_DIR}" || exit 1

# ── USB Device Descriptor ────────────────────────────────────────────────────
# 0x1d6b / 0x0104 : Linux Foundation - Multifunction Composite Gadget
# bcdUSB 0x0200   : USB 2.0 — required for RHEL udev enumeration
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct
echo "0x0200" > bcdUSB
echo "0x0100" > bcdDevice

# ── String Descriptors ───────────────────────────────────────────────────────
mkdir -p strings/0x409
echo "Nuvoton"                       > strings/0x409/manufacturer
echo "BMC USB Network Unit-${UNIT}"  > strings/0x409/product
echo "NPCM845USB-UNIT${UNIT}"        > strings/0x409/serialnumber

# ── Configuration ────────────────────────────────────────────────────────────
mkdir -p configs/c.1/strings/0x409
echo "CDC ECM"  > configs/c.1/strings/0x409/configuration
echo 250        > configs/c.1/MaxPower

# ── CDC ECM Function ─────────────────────────────────────────────────────────
mkdir -p functions/ecm.usb0
echo "${BMC_MAC}"  > functions/ecm.usb0/dev_addr
echo "${HOST_MAC}" > functions/ecm.usb0/host_addr

ln -s "$(pwd)/functions/ecm.usb0" configs/c.1/

# ── Bind to UDC ──────────────────────────────────────────────────────────────
echo "${UDC_NAME}" > UDC

echo "USB CDC ECM gadget started (UDC: ${UDC_NAME})"

# ── Wait for usb0 interface to appear ────────────────────────────────────────
RETRY=0
while [ ${RETRY} -lt 10 ]; do
    ip link show "${IFACE}" > /dev/null 2>&1 && break
    sleep 1
    RETRY=$(( RETRY + 1 ))
done

if ! ip link show "${IFACE}" > /dev/null 2>&1; then
    echo "WARNING: ${IFACE} interface did not appear after 10s" >&2
    exit 1
fi

# ── Assign static IP to BMC's usb0 ───────────────────────────────────────────
# Note: No DHCP server is running on this interface.
#       The host side (${HOST_IP}) must be configured manually or via
#       a NetworkManager static connection profile on the RHEL host.
ip link set "${IFACE}" up
ip addr flush dev "${IFACE}" 2>/dev/null || true
ip addr add "${BMC_IP}/${BMC_PREFIX}" dev "${IFACE}"
echo "BMC USB network: unit=${UNIT} IP=${BMC_IP}/${BMC_PREFIX} on ${IFACE}"
echo "Host should use static IP: ${HOST_IP}/${BMC_PREFIX}"

exit 0
