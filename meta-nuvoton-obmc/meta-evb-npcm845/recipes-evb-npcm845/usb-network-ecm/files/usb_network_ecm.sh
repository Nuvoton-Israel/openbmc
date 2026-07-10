#!/bin/sh
#
# usb_network_ecm.sh
# Configure USB gadget as CDC ECM network interface.
#
# Compatible with: Red Hat / RHEL / Fedora (uses cdc_ether driver, auto-detected)
#                  Linux (standard CDC ECM)
#                  macOS (standard CDC ECM)
#
# Network layout:
#   BMC  (usb0): 192.168.7.2/24  ← static
#
# On RHEL, NetworkManager will:
#   1. Auto-detect the CDC ECM USB NIC (cdc_ether driver loads automatically)
#   2. Run DHCP → get 192.168.7.1 from BMC's dnsmasq
#   3. Interface is up and reachable
#
# SSH to BMC from RHEL host:
#   ssh root@192.168.7.2

GADGET_NAME="cdc_ecm"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
BMC_IP="192.168.7.1"
BMC_PREFIX="24"
IFACE="vport1"

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
    UDC_NAME="ci_hdrc.3"
else
    UDC_NAME="f0833000.udc"
fi
UDC_NAME="${UDC_OVERRIDE:-${UDC_NAME}}"

# ── Reload system dnsmasq to pick up USB DHCP config ────────────────────────
# The usb-dhcp.conf drop-in is installed at /etc/dnsmasq.d/usb-dhcp.conf
# Sending SIGHUP tells the system dnsmasq to reload config without restarting.
reload_dnsmasq() {
    if kill -HUP "$(cat /var/run/dnsmasq.pid 2>/dev/null)" 2>/dev/null; then
        echo "System dnsmasq reloaded — ${IFACE} DHCP active (${BMC_IP} → RHEL host)"
    else
        # Fallback: restart via systemctl if SIGHUP fails
        systemctl restart dnsmasq 2>/dev/null && \
            echo "System dnsmasq restarted — ${IFACE} DHCP active" || \
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
#
# NOTE: The kernel names ECM interfaces usb0, usb1... regardless of the
# function directory name.  Interface renaming to "${IFACE}" is handled
# by the systemd .link file (10-bmc-usb-ecm.link) matching by MAC address.
mkdir -p functions/ecm.usb0
echo "${BMC_MAC}"  > functions/ecm.usb0/dev_addr
echo "${HOST_MAC}" > functions/ecm.usb0/host_addr

ln -s "$(pwd)/functions/ecm.usb0" configs/c.1/

# ── Bind to UDC ──────────────────────────────────────────────────────────────
# Wait for the UDC device to appear before binding. Binding to a UDC that has
# not yet been probed by the kernel can block or fail, which leaves this
# oneshot service hanging and stalls multi-user.target intermittently.
RETRY=0
while [ ${RETRY} -lt 20 ]; do
    [ -e "/sys/class/udc/${UDC_NAME}" ] && break
    sleep 1
    RETRY=$(( RETRY + 1 ))
done
if [ ! -e "/sys/class/udc/${UDC_NAME}" ]; then
    echo "WARNING: UDC ${UDC_NAME} not present, skipping gadget bind" >&2
    exit 0
fi
echo "${UDC_NAME}" > UDC

echo "USB CDC ECM gadget started (UDC: ${UDC_NAME})"

(
# ── Wait for kernel-created gadget net interface ───────────────────────────
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
    echo "ERROR: CDC ECM gadget interface with MAC ${BMC_MAC} did not appear after 20s" >&2
    exit 1
fi

echo "CDC ECM gadget interface appeared as: ${KERNEL_IFACE}"

# ── Rename to the stable name (if not already correct) ───────────────────────
if [ "${KERNEL_IFACE}" != "${IFACE}" ]; then
    ip link set "${KERNEL_IFACE}" down 2>/dev/null || true
    ip link set "${KERNEL_IFACE}" name "${IFACE}"
    echo "Renamed ${KERNEL_IFACE} -> ${IFACE}"
fi

# IP assignment is handled by systemd-networkd via 00-bmc-usb0-ecm.network
echo "Interface ${IFACE} ready — IP will be assigned by systemd-networkd"
) &

exit 0