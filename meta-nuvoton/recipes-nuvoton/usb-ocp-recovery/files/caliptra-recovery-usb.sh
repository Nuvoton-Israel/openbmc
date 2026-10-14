#!/bin/sh
# Recover the Caliptra MCU over USB OCP, bring up MCTP-over-USB, then push a
# PLDM firmware package to it.
#
# usage: caliptra-recovery-usb.sh [FW_DIR]
#   Uses the firmware images installed in the image under FW_DIR (default:
#   /usr/share/usb-ocp-recovery). usb_ocp_recovery and caliptra_mcu.cfg also
#   come from the image.
#
# Demo presentation (environment, all optional):
#   DEMO_BIG=0        plain banners instead of DEC double-height lines, for
#                     terminals that do not support ESC#3/ESC#4

set -e

FW_DIR=${1:-/usr/share/usb-ocp-recovery}
PLDM_PKG=$FW_DIR/NPCM5_pldm.bin
MCTP_IF=mctpusb0
WAIT_SEC=30
PLDM_TIMEOUT_SEC=600
DEMO_BIG=${DEMO_BIG:-1}

if [ -t 1 ]; then
    ESC=$(printf '\033')
    C_RESET="$ESC[0m"
    C_TITLE="$ESC[1;36m"
    C_OK="$ESC[1;32m"
    C_INFO="$ESC[1;33m"
    C_ERR="$ESC[1;31m"
else
    ESC= C_RESET= C_TITLE= C_OK= C_INFO= C_ERR=
fi

# Step banner. Double-height lines are also double-width, so keep the text
# under 40 characters.
banner() {
    color=$1
    shift
    if [ -z "$ESC" ]; then
        printf '\n==> %s\n' "$*"
    elif [ "$DEMO_BIG" != 0 ]; then
        printf '\n%s%s#3%s\n%s#4%s%s\n' "$color" "$ESC" "$*" "$ESC" "$*" "$C_RESET"
    else
        printf '\n%s>> %s%s\n' "$color" "$*" "$C_RESET"
    fi
}

note() {
    color=$1
    shift
    printf '   %s%s%s\n' "$color" "$*" "$C_RESET"
}

die() {
    printf '\n%s   error: %s%s\n' "$C_ERR" "$*" "$C_RESET" >&2
    exit 1
}

# Print VID:PID / product strings of a /dev/bus/usb/BBB/DDD node from sysfs.
usb_describe() {
    bus=$(expr "$(basename "$(dirname "$1")")" + 0)
    dev=$(expr "$(basename "$1")" + 0)
    for s in /sys/bus/usb/devices/*; do
        [ "$(cat "$s/busnum" 2>/dev/null)" = "$bus" ] || continue
        [ "$(cat "$s/devnum" 2>/dev/null)" = "$dev" ] || continue
        note "$C_INFO" "USB ID        : $(cat "$s/idVendor"):$(cat "$s/idProduct")"
        [ -r "$s/manufacturer" ] &&
            note "$C_INFO" "Manufacturer  : $(cat "$s/manufacturer")"
        [ -r "$s/product" ] &&
            note "$C_INFO" "Product       : $(cat "$s/product")"
        [ -r "$s/speed" ] &&
            note "$C_INFO" "Speed         : $(cat "$s/speed") Mbps"
        return 0
    done
}

# One-line progress bar: progress_bar PERCENT TEXT
# Kept under 80 columns so a carriage return redraws it in place on a serial
# console; ESC[K clears leftovers from a longer previous line.
progress_bar() {
    awk -v p="$1" -v t="$2" -v g="$C_OK" -v r="$C_RESET" -v e="$ESC" 'BEGIN {
        w = 30; f = int(p * w / 100); bar = "";
        for (i = 0; i < w; i++) bar = bar (i < f ? "#" : "-");
        printf "\r%s   [%s%s%s] %3d%%  %s", (e != "" ? e "[K" : ""), g, bar, r, p, t;
    }'
}

for f in runtime-npcm500.bin NPCM5_pldm.bin soc_manifest.bin caliptra_fw.bin; do
    [ -r "$FW_DIR/$f" ] || die "missing firmware $FW_DIR/$f"
done

# The recovery device has no fixed bus/dev number, so find it as the usbfs node
# that appears after the MCU is released.
before=$(ls /dev/bus/usb/*/* 2>/dev/null || true)

gpioset 2 6=0
openocd -f caliptra_mcu.cfg -c init \
    -c "mwb 0x400C3069 0x60" -c "mwb 0x400C3069 0x40" \
    -c resume -c "riscv.tap.0 curstate" -c shutdown

# ---------------------------------------------------------------------------
banner "$C_TITLE" "Detecting USB OCP Recovery Device"
note "$C_INFO" "Waiting for the Caliptra MCU to enumerate on USB ..."
usbdev=
i=0
while [ -z "$usbdev" ]; do
    [ $i -lt $WAIT_SEC ] || die "no new USB device after ${WAIT_SEC}s"
    sleep 1
    i=$((i + 1))
    for d in /dev/bus/usb/*/*; do
        echo "$before" | grep -qx "$d" || { usbdev=$d; break; }
    done
done
note "$C_OK" "[OK] USB OCP recovery device detected: $usbdev"
usb_describe "$usbdev"

# ---------------------------------------------------------------------------
# Banners for capability read and streaming boot come from usb_ocp_recovery.
OCP_DEMO_BIG=$DEMO_BIG \
usb_ocp_recovery --fifo "$usbdev" \
    "$FW_DIR/caliptra_fw.bin" "$FW_DIR/soc_manifest.bin" "$FW_DIR/runtime-npcm500.bin"

# ---------------------------------------------------------------------------
banner "$C_TITLE" "Bring up MCTP over USB"
note "$C_INFO" "Waiting for $MCTP_IF from the recovered firmware ..."
i=0
until [ -e /sys/class/net/$MCTP_IF ]; do
    [ $i -lt $WAIT_SEC ] || die "$MCTP_IF did not appear after ${WAIT_SEC}s"
    sleep 1
    i=$((i + 1))
done

mctp link set $MCTP_IF up
mctp addr add 8 dev $MCTP_IF
note "$C_OK" "[OK] $MCTP_IF is up, BMC EID 8"

# ---------------------------------------------------------------------------
banner "$C_TITLE" "Discover MCTP Endpoint"
ep=$(busctl call au.com.codeconstruct.MCTP1 \
    /au/com/codeconstruct/mctp1/interfaces/$MCTP_IF \
    au.com.codeconstruct.MCTP.BusOwner1 \
    SetupEndpoint ay 0)
# reply: yisb EID NET PATH NEW
eid=$(echo "$ep" | awk '{ print $2 }')
note "$C_OK" "[OK] Caliptra MCU endpoint assigned EID $eid"

systemctl restart pldmd
sleep 1

# ---------------------------------------------------------------------------
banner "$C_TITLE" "PLDM Firmware Update"
pkg_size=$(wc -c < "$PLDM_PKG")
note "$C_INFO" "Package       : $(basename "$PLDM_PKG") ($pkg_size bytes)"
note "$C_INFO" "Transport     : PLDM Type 5 over MCTP over USB (EID $eid)"

# Transfer progress comes from the bytes the BMC sends on the MCTP interface:
# every RequestFirmwareData response carries one block of the package. mctp-usb
# counts the 4-byte USB transport header and 4-byte MCTP header of every packet
# in tx_bytes, so subtract those to estimate firmware payload. Phase completion
# comes from pldmd's info-level journal messages.
tx_stat=/sys/class/net/$MCTP_IF/statistics/tx_bytes
txp_stat=/sys/class/net/$MCTP_IF/statistics/tx_packets
PKT_HDR=8
jlog=$(mktemp)
journalctl -u pldmd -f -n 0 -o cat > "$jlog" 2>/dev/null &
jpid=$!
trap 'kill $jpid 2>/dev/null; rm -f "$jlog"' EXIT

tx0=$(cat "$tx_stat")
txp0=$(cat "$txp_stat")
reply=$(busctl call xyz.openbmc_project.PLDM \
    /xyz/openbmc_project/software/pldm \
    xyz.openbmc_project.Software.Update \
    StartUpdate hs 3 \
    xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate \
    3< "$PLDM_PKG")
obj=$(echo "$reply" | sed -n 's/^o "\(.*\)"$/\1/p')
[ -n "$obj" ] || die "StartUpdate returned no software object: $reply"

start=$(date +%s)
pct=0
phase="Starting update"
while :; do
    act=$(busctl get-property xyz.openbmc_project.PLDM "$obj" \
        xyz.openbmc_project.Software.Activation Activation 2>/dev/null |
        sed 's/.*\.\([A-Za-z]*\)"$/\1/') || true

    # Transfer covers 0-90%, verify 90-95%, apply 95-100%.
    sent=$(( $(cat "$tx_stat") - tx0 - ($(cat "$txp_stat") - txp0) * PKT_HDR ))
    [ $sent -le $pkg_size ] || sent=$pkg_size
    if grep -q "apply complete" "$jlog"; then
        pct=100 phase="Applied"
    elif grep -q "verification complete" "$jlog"; then
        pct=95 phase="Applying firmware"
    elif grep -q "transfer complete" "$jlog"; then
        pct=90 phase="Verifying firmware"
    elif [ $sent -gt 1024 ]; then
        pct=$(( sent * 90 / pkg_size ))
        [ $pct -le 89 ] || pct=89
        phase="Transferring $(( sent / 1024 ))/$(( pkg_size / 1024 )) KB"
    fi

    case "$act" in
    Active)
        progress_bar 100 "Update complete"
        echo
        break
        ;;
    Failed | Invalid)
        echo
        die "PLDM firmware update $act"
        ;;
    esac

    progress_bar "$pct" "$phase"
    [ $(( $(date +%s) - start )) -lt $PLDM_TIMEOUT_SEC ] ||
        { echo; die "PLDM firmware update timed out"; }
    sleep 1
done

banner "$C_OK" "PLDM Firmware Update Complete"
note "$C_OK" "[OK] Firmware updated in $(( $(date +%s) - start ))s"
