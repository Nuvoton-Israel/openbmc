#!/bin/sh
#
# usb_network.sh
# Configure USB gadget as CDC ECM network interface.
#
# Compatible with: Red Hat / RHEL / Fedora (uses cdc_ether driver, auto-detected)
#                  Linux (standard CDC ECM)
#                  macOS (standard CDC ECM)
#
# Network layout:
#   BMC  (usb0): 192.168.7.2/24  ← static
#   Host (ethX): 192.168.7.1/24  ← assigned via DHCP (dnsmasq on BMC)
#
# On RHEL, NetworkManager will:
#   1. Auto-detect the CDC ECM USB NIC (cdc_ether driver loads automatically)
#   2. Run DHCP → get 192.168.7.1 from BMC's dnsmasq
#   3. Interface is up and reachable
#
# SSH to BMC from RHEL host:
#   ssh root@192.168.7.2

GADGET_NAME="g1"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
BMC_IP="192.168.7.2"
BMC_PREFIX="24"
IFACE="usb0"

# Fixed MAC addresses — required for stable NetworkManager profiles on RHEL
# Host-side MAC must be unicast (LSB of first byte = 0)
BMC_MAC="02:00:11:22:33:44"   # BMC side (dev_addr)
HOST_MAC="02:00:55:66:77:88"  # host side (host_addr)

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

# ── Reload system dnsmasq to pick up usb0 DHCP config ───────────────────────
# The usb0-dhcp.conf drop-in is installed at /etc/dnsmasq.d/usb0-dhcp.conf
# Sending SIGHUP tells the system dnsmasq to reload config without restarting.
reload_dnsmasq() {
    if kill -HUP "$(cat /var/run/dnsmasq.pid 2>/dev/null)" 2>/dev/null; then
        echo "System dnsmasq reloaded — usb0 DHCP active (192.168.7.1 → RHEL host)"
    else
        # Fallback: restart via systemctl if SIGHUP fails
        systemctl restart dnsmasq 2>/dev/null && \
            echo "System dnsmasq restarted — usb0 DHCP active" || \
            echo "WARNING: could not reload dnsmasq" >&2
    fi
}

# ── Skip if gadget already configured ────────────────────────────────────────
if [ -d "${GADGET_DIR}" ]; then
    echo "USB network gadget already configured, skipping."
    # Still ensure IP is assigned and dnsmasq has usb0 config loaded
    ip addr show dev "${IFACE}" | grep -q "${BMC_IP}" || \
        ip addr add "${BMC_IP}/${BMC_PREFIX}" dev "${IFACE}" 2>/dev/null || true
    ip link set "${IFACE}" up 2>/dev/null || true
    reload_dnsmasq
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
echo "Nuvoton"              > strings/0x409/manufacturer
echo "BMC USB Network"      > strings/0x409/product
echo "NPCM845USB0001"       > strings/0x409/serialnumber

# ── Configuration ────────────────────────────────────────────────────────────
mkdir -p configs/c.1/strings/0x409
echo "CDC ECM"              > configs/c.1/strings/0x409/configuration
echo 250                    > configs/c.1/MaxPower

# ── CDC ECM Function ─────────────────────────────────────────────────────────
# CDC ECM: standard USB networking class, supported natively by:
#   - RHEL/CentOS/Fedora : cdc_ether module (auto-loaded by udev)
#   - Debian/Ubuntu      : cdc_ether module
#   - macOS              : built-in
#   - Windows 10/11      : requires driver (RNDIS preferred for Windows)
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
ip link set "${IFACE}" up
ip addr flush dev "${IFACE}" 2>/dev/null || true
ip addr add "${BMC_IP}/${BMC_PREFIX}" dev "${IFACE}"
echo "BMC USB network IP: ${BMC_IP}/${BMC_PREFIX} on ${IFACE}"

# ── Reload system dnsmasq to activate usb0 DHCP ─────────────────────────────
# /etc/dnsmasq.d/usb0-dhcp.conf is already installed.
# SIGHUP causes dnsmasq to re-read config and start serving usb0.
reload_dnsmasq

exit 0
