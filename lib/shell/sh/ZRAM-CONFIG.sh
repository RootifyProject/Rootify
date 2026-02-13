#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Consolidated ZRAM Configuration Script
# Handles: swapoff -> reset -> algorithm -> size -> swapon
#

SIZE_MB=$1
ALGO=$2
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_SIZE="$MODULE_DIR/configs/ZRAM-SIZE"
DATA_ALGO="$MODULE_DIR/configs/ZRAM-ALGHORITM"

# ANALOGIES FOR SCENARIOS:
# 1. BOTH CHANGE: Changing the engine (algo) AND the fuel tank (size). Must stop the car (swapoff) and clear the dash (reset).
# 2. ONLY SIZE: Expanding the fuel tank. Even if the engine is the same, you can't weld a new tank while driving. Stop and reset.
# 3. ONLY ALGO: Keeping the same tank but swapping the engine. Must stop and reset.
# 4. SET 1 (MINIMAL): Setting tiny size. Works, but still needs a full stop to reconfigure.
# 5. SCALE (MAXIMAL): Setting 16GB+. Kernel will check RAM limits, but the procedure remains the same: Stop -> Reset -> Apply.
# 6. RE-APPLY: If settings are exactly the same, we check first to avoid "re-tuning" a car that's already perfect.
# 7. PIT STOP: Updating settings while the system is under load. swapoff might take time as it moves data back to RAM.
# 8. COLD START: Applying during boot. The script ensures the workbench is clean before starting.
# 9. TIRE PRESSURE: (VFS) Clearing cache pressure. Important for disk responsiveness while swap is busy.
# 10. ACCELERATION: (Swappiness) Deciding how early the engine uses the compressed fuel.
# 11. EMPTYING THE TRUNK: Forcing swapoff ensures no data is trapped in a device we're about to reset.
# 12. CHECKING THE MANUAL: Reading current /sys nodes before acting avoids unnecessary work.

# 0. Check current state to avoid redundant cycles
CUR_SIZE_BYTES=$(cat /sys/block/zram0/disksize 2>/dev/null)
CUR_SIZE_MB=$((CUR_SIZE_BYTES / 1024 / 1024))
# Algorithm check is harder due to [] notation, but we can read it.
CUR_ALGO=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null | sed 's/.*\[\(.*\)\].*/\1/')

if [ "$SIZE_MB" -eq "$CUR_SIZE_MB" ] && [ "$ALGO" = "$CUR_ALGO" ]; then
    # Car is already in the right config. Check if swap is on.
    if grep -q "/dev/block/zram0" /proc/swaps; then
        echo "LOG: ZRAM already correctly configured ($ALGO, ${SIZE_MB}MB). Skipping reset."
        exit 0
    fi
fi

# 1. Stop Swap (Forcefully)
# 1. Stop Swap (Forcefully)
swapoff /dev/block/zram0
RET=$?
if [ $RET -ne 0 ]; then
    echo "LOG: swapoff returned $RET (might be already off)"
    # Continue, but warn. If it was busy, reset might fail.
fi

# 2. Reset Device (Crucial for changing algorithm/size)
echo "LOG: Resetting zram0..."
echo 1 > /sys/block/zram0/reset || { echo "ERROR: Failed to reset zram0 (Device busy?)"; exit 1; }

# 3. Apply Algorithm
if [ -n "$ALGO" ]; then
    echo "LOG: Applying algorithm: $ALGO"
    if [ -f "$BIN" ]; then
        "$BIN" zram-algo "$ALGO"
        RET=$?
        if [ $RET -ne 0 ]; then
             echo "LOG: ROOTIFY zram-algo failed (code $RET), falling back to shell..."
             echo "$ALGO" > /sys/block/zram0/comp_algorithm || echo "WARNING: Failed to set algorithm '$ALGO' via shell"
        fi
    else
        echo "$ALGO" > /sys/block/zram0/comp_algorithm || echo "WARNING: Failed to write to comp_algorithm via shell"
    fi
    # Persistence
    echo "$ALGO" > "$DATA_ALGO"
fi

# 4. Apply Size
if [ -n "$SIZE_MB" ] && [ "$SIZE_MB" -gt 0 ]; then
    echo "LOG: Applying size: ${SIZE_MB}MB"
    if [ -f "$BIN" ]; then
        "$BIN" zram-size "$SIZE_MB"
        RET=$?
        if [ $RET -ne 0 ]; then
             echo "LOG: ROOTIFY zram-size failed (code $RET), falling back to shell..."
             SIZE_BYTES=$((SIZE_MB * 1024 * 1024))
             echo "$SIZE_BYTES" > /sys/block/zram0/disksize || { echo "ERROR: Failed to write to disksize"; exit 1; }
        fi
    else
        SIZE_BYTES=$((SIZE_MB * 1024 * 1024))
        echo "$SIZE_BYTES" > /sys/block/zram0/disksize || { echo "ERROR: Failed to write to disksize"; exit 1; }
    fi
    # Persistence
    echo "$SIZE_MB" > "$DATA_SIZE"
fi

# 5. Initialize & Start
mkswap /dev/block/zram0 || { echo "ERROR: mkswap failed"; exit 1; }
swapon /dev/block/zram0 || { echo "ERROR: swapon failed"; exit 1; }
echo "LOG: ZRAM configuration successful"



# 6. Final Verification
CURRENT_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)
if [ "$CURRENT_SIZE" -eq 0 ] && [ "$SIZE_MB" -gt 0 ]; then
    echo "ERROR: ZRAM size is 0 after application"
    exit 1
fi

if [ -n "$SIZE_MB" ] && [ "$SIZE_MB" -gt 0 ]; then
    CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
    # Allow 1-2MB variance due to rounding
    DIFF=$((CURRENT_MB - SIZE_MB))
    if [ "$DIFF" -lt -5 ] || [ "$DIFF" -gt 5 ]; then
        echo "WARNING: Requested ${SIZE_MB}MB, but got ${CURRENT_MB}MB. Kernel likely clamped the value."
    fi
fi

exit 0
