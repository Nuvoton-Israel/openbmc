#!/bin/sh
#
# format_emmc.sh
# Format the BMC's eMMC as a single ext4 partition.
# Compatible with OpenBMC's busybox environment (no gdisk/lsblk needed).
#
# ⚠️  WARNING: This will ERASE ALL DATA on the eMMC device.
#              Run this ONLY when booting from SPI flash (not from eMMC).
#
# Usage:
#   format_emmc.sh [device]
#   device : eMMC block device (default: /dev/mmcblk0)
#

MMC_DEVICE="${1:-/dev/mmcblk0}"
PARTITION="${MMC_DEVICE}p1"
LABEL="storage"
DEV_NAME=$(basename "${MMC_DEVICE}")

# ── Validate device ──────────────────────────────────────────────────────────
if [ ! -b "${MMC_DEVICE}" ]; then
    echo "ERROR: Block device '${MMC_DEVICE}' not found." >&2
    echo "Available block devices:" >&2
    cat /proc/partitions >&2
    exit 1
fi

# ── Show device info ─────────────────────────────────────────────────────────
SECTORS=$(cat "/sys/block/${DEV_NAME}/size" 2>/dev/null || echo 0)
SIZE_MB=$(( SECTORS / 2048 ))
echo "========================================"
echo "  eMMC Format Utility"
echo "========================================"
echo "  Device : ${MMC_DEVICE}"
echo "  Size   : ${SIZE_MB} MB"
echo "  Label  : ${LABEL}"
echo "  FS     : ext4"
echo "========================================"
echo ""
echo "WARNING: ALL DATA on ${MMC_DEVICE} will be PERMANENTLY ERASED."
echo ""
printf "Type 'yes' to confirm: "
read -r CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# ── Unmount all partitions (if mounted) ──────────────────────────────────────
echo ""
echo "[1/4] Unmounting any mounted partitions..."
for part in "${MMC_DEVICE}"p*; do
    if [ -b "${part}" ]; then
        if grep -q "^${part} " /proc/mounts 2>/dev/null; then
            MNTPT=$(grep "^${part} " /proc/mounts | awk '{print $2}')
            echo "      Unmounting ${part} from ${MNTPT}"
            umount "${part}" 2>/dev/null || true
        fi
    fi
done

# ── Wipe existing partition table ────────────────────────────────────────────
echo "[2/4] Wiping existing partition table..."
dd if=/dev/zero of="${MMC_DEVICE}" bs=512 count=4096 2>/dev/null
if [ "${SECTORS}" -gt 8192 ]; then
    SKIP=$(( SECTORS - 4096 ))
    dd if=/dev/zero of="${MMC_DEVICE}" bs=512 seek="${SKIP}" count=4096 2>/dev/null || true
fi
sync

# ── Create MBR partition table with single primary partition ─────────────────
# Using busybox fdisk (available on all OpenBMC images)
# Commands:
#   o  - create new empty MBR partition table
#   n  - new partition
#   p  - primary
#   1  - partition number 1
#   (enter) - first sector (default: 2048, 1MB aligned)
#   (enter) - last sector  (default: end of disk)
#   t  - change type
#   83 - Linux
#   w  - write table and exit
echo "[3/4] Creating single partition (MBR)..."
printf 'o\nn\np\n1\n\n\nt\n83\nw\n' | fdisk "${MMC_DEVICE}" 2>&1

# ── Trigger kernel partition table re-read ───────────────────────────────────
# sysfs rescan (OpenBMC / NPCM eMMC path)
sync
echo 1 > "/sys/block/${DEV_NAME}/device/rescan" 2>/dev/null || true
sleep 2

# If partition node still doesn't exist, try mdev to trigger uevent
if [ ! -b "${PARTITION}" ]; then
    mdev -s 2>/dev/null || true
    sleep 1
fi

# Last resort: check if kernel recognizes it via /proc/partitions
if ! grep -q "${DEV_NAME}p1" /proc/partitions 2>/dev/null; then
    echo "ERROR: Partition ${PARTITION} not found after partitioning." >&2
    echo "       /proc/partitions:" >&2
    cat /proc/partitions >&2
    echo "       → Try rebooting and running this script again." >&2
    exit 1
fi

# Create the device node manually if it's missing (mdev may not have run)
if [ ! -b "${PARTITION}" ]; then
    MAJOR=$(awk "\$4==\"${DEV_NAME}\" {print \$1}" /proc/partitions)
    MINOR=$(awk "\$4==\"${DEV_NAME}p1\" {print \$2}" /proc/partitions)
    if [ -n "${MAJOR}" ] && [ -n "${MINOR}" ]; then
        mknod "${PARTITION}" b "${MAJOR}" "${MINOR}"
    fi
fi

# ── Format as ext4 ───────────────────────────────────────────────────────────
echo "[4/4] Formatting ${PARTITION} as ext4 (label: ${LABEL})..."
mkfs.ext4 -F -L "${LABEL}" "${PARTITION}"

# ── Done ─────────────────────────────────────────────────────────────────────
PART_SECTORS=$(cat "/sys/block/${DEV_NAME}/${DEV_NAME}p1/size" 2>/dev/null || echo 0)
PART_MB=$(( PART_SECTORS / 2048 ))
echo ""
echo "========================================"
echo "  Format complete!"
echo "========================================"
echo "  Partition : ${PARTITION}"
echo "  Size      : ${PART_MB} MB"
echo "  Label     : ${LABEL}"
echo "  Filesystem: ext4"
echo ""
echo "  To mount:"
echo "    mkdir -p /mnt/emmc && mount ${PARTITION} /mnt/emmc"
echo "========================================"
exit 0
