#!/bin/sh
# Recover the Caliptra MCU over USB OCP, bring up MCTP-over-USB, then push a
# PLDM firmware package to it.
#
# usage: caliptra-recovery-usb.sh [FW_DIR]
#   Uses the firmware images installed in the image under FW_DIR (default:
#   /usr/share/usb-ocp-recovery). usb_ocp_recovery and caliptra_mcu.cfg also
#   come from the image.

set -e

FW_DIR=${1:-/usr/share/usb-ocp-recovery}
PLDM_PKG=$FW_DIR/NPCM5_pldm.bin
MCTP_IF=mctpusb0
WAIT_SEC=30

die() { echo "error: $*" >&2; exit 1; }

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
echo "recovery device: $usbdev"

usb_ocp_recovery --fifo "$usbdev" \
    "$FW_DIR/caliptra_fw.bin" "$FW_DIR/soc_manifest.bin" "$FW_DIR/runtime-npcm500.bin"

i=0
until [ -e /sys/class/net/$MCTP_IF ]; do
    [ $i -lt $WAIT_SEC ] || die "$MCTP_IF did not appear after ${WAIT_SEC}s"
    sleep 1
    i=$((i + 1))
done

mctp link set $MCTP_IF up
mctp addr add 8 dev $MCTP_IF

busctl call au.com.codeconstruct.MCTP1 \
    /au/com/codeconstruct/mctp1/interfaces/$MCTP_IF \
    au.com.codeconstruct.MCTP.BusOwner1 \
    SetupEndpoint ay 0

systemctl restart pldmd
sleep 1

busctl call xyz.openbmc_project.PLDM \
    /xyz/openbmc_project/software/pldm \
    xyz.openbmc_project.Software.Update \
    StartUpdate hs 3 \
    xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.Immediate \
    3< "$PLDM_PKG"
