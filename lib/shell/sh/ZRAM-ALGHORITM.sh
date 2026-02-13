#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Handles ZRAM algorithm selection
#

ALGO=$1
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/ZRAM-ALGHORITM"

# 1. Stop Swap (Required to change algo)
swapoff /dev/block/zram0 || echo "LOG: swapoff already off"
echo 1 > /sys/block/zram0/reset || { echo "ERROR: reset failed"; exit 1; }

# 2. Apply Algo
if [ -f "$BIN" ]; then
    "$BIN" zram-algo "$ALGO" || { echo "ERROR: ROOTIFY zram-algo failed"; exit 1; }
else
    echo "$ALGO" > /sys/block/zram0/comp_algorithm || { echo "ERROR: failed to write algo"; exit 1; }
fi

# 3. Persistence
if [ $? -eq 0 ]; then
    echo "$ALGO" > "$DATA_FILE"
fi

exit 0
