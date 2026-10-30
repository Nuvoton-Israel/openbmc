#!/bin/sh
#
# usb_satellite_link.sh
# Configure the USB gadget of a Satellite BMC:
#   satellite_link  (first free UDC): ecm.usb0
#       CDC ECM network, Redfish reachable at 192.168.7.1 (aggregator: 192.168.7.2)
#
# The aggregator BMC is the USB host: its cdc_ether driver creates the network
# interface.

GADGET_NAME="satellite_link"
GADGET_DIR="/sys/kernel/config/usb_gadget/${GADGET_NAME}"
IFACE="sat0"

# Distinct from the generic usb-network-ecm recipe (02:00:11:22:33:44 / 02:00:55:66:77:88)
BMC_MAC="02:00:a1:b2:c3:01"   # satellite side (dev_addr)
HOST_MAC="02:00:a1:b2:c3:02"  # aggregator side (host_addr)

if ! mountpoint -q /sys/kernel/config 2>/dev/null; then
    mount -t configfs none /sys/kernel/config
fi

# UDCs are detected dynamically: every controller in /sys/class/udc that is not
# already bound to another gadget is a candidate (lowest number first).  The
# ECM gadget takes the first free one.
# UDC_OVERRIDE forces a specific controller (e.g. ci_hdrc.3).
ECM_UDC="${UDC_OVERRIDE:-}"

# True if <udc> is bound to any gadget in configfs
udc_in_use() {
    for f in /sys/kernel/config/usb_gadget/*/UDC; do
        [ -e "${f}" ] || continue
        [ "$(cat "${f}" 2>/dev/null)" = "$1" ] && return 0
    done
    return 1
}

# Bind the current gadget (cwd) to the first free UDC.  With a forced name only
# that UDC is tried.  A UDC that is not probed yet is waited for.
bind_free_udc() {
    forced="$1"
    RETRY=0
    while [ ${RETRY} -lt 20 ]; do
        if [ -n "${forced}" ]; then
            [ -e "/sys/class/udc/${forced}" ] && break
        else
            [ -n "$(ls /sys/class/udc 2>/dev/null)" ] && break
        fi
        sleep 1
        RETRY=$(( RETRY + 1 ))
    done

    if [ -n "${forced}" ]; then
        candidates="${forced}"
    else
        candidates=$(ls /sys/class/udc 2>/dev/null | sort -V)
    fi

    for u in ${candidates}; do
        [ -e "/sys/class/udc/${u}" ] || continue
        udc_in_use "${u}" && continue
        if echo "${u}" > UDC 2>/dev/null; then
            BOUND_UDC="${u}"
            return 0
        fi
    done
    return 1
}

# setup_gadget <name> <product> <serial> <forced-udc> <function-setup-callback>
# Creates /sys/kernel/config/usb_gadget/<name>, adds the function(s) and binds
# it to the first free UDC.
setup_gadget() {
    name="$1"; product="$2"; serial="$3"; forced="$4"; setup_functions="$5"
    dir="/sys/kernel/config/usb_gadget/${name}"

    if [ -d "${dir}" ]; then
        echo "USB gadget ${name} already configured, skipping."
        return 0
    fi

    mkdir -p "${dir}"
    cd "${dir}" || return 1

    echo "0x1d6b" > idVendor
    echo "0x0104" > idProduct
    echo "0x0200" > bcdUSB
    echo "0x0100" > bcdDevice

    mkdir -p strings/0x409
    echo "Nuvoton"   > strings/0x409/manufacturer
    echo "${product}" > strings/0x409/product
    echo "${serial}"  > strings/0x409/serialnumber

    mkdir -p configs/c.1/strings/0x409
    echo "${product}" > configs/c.1/strings/0x409/configuration
    echo 250          > configs/c.1/MaxPower

    ${setup_functions}

    if bind_free_udc "${forced}"; then
        echo "USB gadget ${name} started (UDC: ${BOUND_UDC})"
    else
        echo "WARNING: no free UDC for gadget ${name}" >&2
    fi
}

setup_ecm_function() {
    # Interface association (ECM): EF/02/01
    echo "0xEF" > bDeviceClass
    echo "0x02" > bDeviceSubClass
    echo "0x01" > bDeviceProtocol

    # CDC ECM (Redfish / HTTPS)
    mkdir -p functions/ecm.usb0
    echo "${BMC_MAC}"  > functions/ecm.usb0/dev_addr
    echo "${HOST_MAC}" > functions/ecm.usb0/host_addr
    ln -s "$(pwd)/functions/ecm.usb0" configs/c.1/
}

setup_gadget "${GADGET_NAME}" "Satellite BMC ECM" "NPCM845SAT0001" \
    "${ECM_UDC}" setup_ecm_function

(
# Rename the ECM interface (by the ECM function ifname; MAC matching is ambiguous across gadgets)
RETRY=0
KERNEL_IFACE=""
while [ ${RETRY} -lt 20 ]; do
    # The ECM function reports the name of its own netdev; matching by MAC
    # can pick up another gadget netdev (e.g. the RNDIS one).
    KERNEL_IFACE=$(cat "${GADGET_DIR}/functions/ecm.usb0/ifname" 2>/dev/null)
    [ -n "${KERNEL_IFACE}" ] && [ -e "/sys/class/net/${KERNEL_IFACE}" ] && break
    KERNEL_IFACE=""
    sleep 1
    RETRY=$(( RETRY + 1 ))
done

if [ -z "${KERNEL_IFACE}" ]; then
    echo "ERROR: ECM netdev did not appear" >&2
    exit 1
fi

if [ "${KERNEL_IFACE}" != "${IFACE}" ]; then
    ip link set "${KERNEL_IFACE}" down 2>/dev/null || true
    ip link set "${KERNEL_IFACE}" name "${IFACE}"
fi
ip link set "${IFACE}" up 2>/dev/null || true

ip addr replace 192.168.7.1/24 dev "${IFACE}"
echo "Interface ${IFACE} ready"
) &

exit 0
