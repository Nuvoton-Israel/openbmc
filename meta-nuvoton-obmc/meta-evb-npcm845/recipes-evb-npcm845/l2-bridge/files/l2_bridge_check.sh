#!/bin/bash
#
# L2 bridge (software switch) self-check for the NPCM845 EVB.
#
# Verifies the setup from the "Linux Implementation" design:
#   br0      = L2 switch (MAC learning), pure switch, no IP
#   eth0     = physical upstream port (RGMII/SGMII)
#   vport0   = BMC OOB veth NIC with its own IP (V-Port 0)
#   vport1   = HOST Ethernet out of the USB CDC-ECM NIC (V-Port 1, switch port)
#
# Exit status: 0 if all expected ports are enslaved to br0, 1 otherwise.

BRIDGE="br0"
EXPECTED_PORTS="eth0 vport0br vport1"
L3_IFACES="vport0"

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; RST=$'\e[0m'
rc=0

hr() { printf '%s\n' "----------------------------------------------------------"; }

# 1. Bridge device present?
hr
echo "[1] Bridge device: ${BRIDGE}"
if ip link show "${BRIDGE}" >/dev/null 2>&1; then
    ip -br link show "${BRIDGE}"
else
    echo "${RED}FAIL: bridge ${BRIDGE} does not exist${RST}"
    exit 1
fi

# 2. Enslaved ports
hr
echo "[2] Enslaved ports (expected: ${EXPECTED_PORTS})"
enslaved=$(ip -o link show master "${BRIDGE}" 2>/dev/null | awk -F': ' '{print $2}' | awk '{print $1}')
if [ -z "${enslaved}" ]; then
    echo "${RED}FAIL: no interfaces enslaved to ${BRIDGE}${RST}"
    rc=1
else
    echo "found: ${enslaved}"
fi

for port in ${EXPECTED_PORTS}; do
    if echo "${enslaved}" | grep -qw "${port}"; then
        echo "  ${GRN}OK  ${RST} ${port} -> ${BRIDGE}"
    else
        echo "  ${RED}MISS${RST} ${port} not enslaved to ${BRIDGE}"
        rc=1
    fi
done

# 3. Bridge port link state / STP
hr
echo "[3] Bridge port state"
if command -v bridge >/dev/null 2>&1; then
    bridge -d link show
else
    echo "${YLW}WARN: 'bridge' tool (iproute2) not available${RST}"
fi

# 4. MAC learning table
hr
echo "[4] Forwarding database (MAC learning)"
if command -v bridge >/dev/null 2>&1; then
    bridge fdb show br "${BRIDGE}"
    # Dynamically learned entries are those enslaved to the bridge that are
    # neither "permanent" nor "self" (this kernel does not print "dynamic").
    learned=$(bridge fdb show br "${BRIDGE}" \
        | grep -w "master ${BRIDGE}" \
        | grep -vE "permanent|self" \
        | grep -c .)
    echo "learned (dynamic) entries: ${learned}"
else
    echo "${YLW}WARN: 'bridge' tool not available${RST}"
fi

# 5. BMC OOB address on vport0 (V-Port 0). vport1 is the USB NIC switch port
#    (HOST Ethernet) and intentionally has no BMC-side IP.
hr
echo "[5] BMC OOB address (V-Port 0)"
for iface in ${L3_IFACES}; do
    if ip link show "${iface}" >/dev/null 2>&1; then
        addrs=$(ip -br addr show "${iface}" | awk '{$1=$2=""; print}' | xargs)
        if [ -n "${addrs}" ]; then
            echo "  ${GRN}OK  ${RST} ${iface}: ${addrs}"
        else
            echo "  ${YLW}WARN${RST} ${iface}: no IP yet (DHCP pending?)"
        fi
    else
        echo "  ${RED}FAIL${RST} ${iface} does not exist"
        rc=1
    fi
done

hr
if [ ${rc} -eq 0 ]; then
    echo "${GRN}RESULT: L2 bridge OK${RST}"
else
    echo "${RED}RESULT: L2 bridge has problems (see above)${RST}"
fi
exit ${rc}
