#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Robust ZRAM Size Configuration
# Handles: swapoff -> reset -> size -> swapon
#

SIZE_MB=$1
MODULE_DIR="/data/adb/modules/rootify"
# Use ROOTIFY monolithic as primary, fallback to shell if needed
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/ZRAM-SIZE"

# 0. Check current state
CUR_SIZE_BYTES=$(cat /sys/block/zram0/disksize 2>/dev/null)
CUR_SIZE_MB=$((CUR_SIZE_BYTES / 1024 / 1024))

if [ "$SIZE_MB" -eq "$CUR_SIZE_MB" ]; then
    if grep -q "/dev/block/zram0" /proc/swaps; then
        echo "LOG: ZRAM size already correct (${SIZE_MB}MB). Skipping."
        exit 0
    fi
fi

# 1. Stop & Reset
swapoff /dev/block/zram0 || echo "LOG: swapoff failed or was already off"
echo 1 > /sys/block/zram0/reset || { echo "ERROR: failed to reset zram0"; exit 1; }

# 2. Apply Size
echo "LOG: Applying size: ${SIZE_MB}MB"
if [ -f "$BIN" ]; then
    "$BIN" zram-size "$SIZE_MB" || { echo "ERROR: ROOTIFY zram-size failed"; exit 1; }
else
    SIZE_BYTES=$((SIZE_MB * 1024 * 1024))
    echo "$SIZE_BYTES" > /sys/block/zram0/disksize || { echo "ERROR: Failed to write to disksize"; exit 1; }
fi

# 3. Finalize
mkswap /dev/block/zram0 || { echo "ERROR: mkswap failed"; exit 1; }
swapon /dev/block/zram0 || { echo "ERROR: swapon failed"; exit 1; }
echo "LOG: ZRAM size applied successfully"

# Persistence
if [ $? -eq 0 ]; then
    echo "$SIZE_MB" > "$DATA_FILE"
fi

exit 0
