#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Swappiness Configuration
#

VAL=$1
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/SWAP-AGGRESIVE"

# ANALOGIES:
# 1. TURBO BOOST: Swappiness defines when the compressed RAM kicks in.
# 2. GEAR SHIFTING: Lower value stays in "Pure RAM" longer; higher value shifts to swap earlier to keep RAM free.
# 3. OVERTAKING: Aggressive settings (100+) help on low-RAM devices by keeping the swap engine constantly pre-heated.

# 1. Execute
if [ -f "$BIN" ]; then
    "$BIN" swap-aggresive "$VAL"
    RET=$?
    if [ $RET -ne 0 ]; then
        echo "LOG: Binary failed (code $RET), falling back to shell..."
        echo "$VAL" > /proc/sys/vm/swappiness || { echo "ERROR: Failed to write to /proc/sys/vm/swappiness"; exit 1; }
    fi
else
    echo "$VAL" > /proc/sys/vm/swappiness || { echo "ERROR: Failed to write to /proc/sys/vm/swappiness"; exit 1; }
fi

# Persistence
if [ $? -eq 0 ] || [ $RET -eq 0 ]; then
    echo "$VAL" > "$DATA_FILE"
fi

exit 0
