#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# VFS Cache Pressure Configuration
#

VAL=$1
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/VFS-CACHE"

# ANALOGIES:
# 1. BRAKE SENSITIVITY: Deciding how quickly the system lets go of old memories (file shortcuts).
# 2. CLEARING THE DESK: Higher value means the system is more aggressive at clearing the workspace to make room.
# 3. STEADY RIDE: A balanced value (100) keeps common shortcuts ready without cluttering RAM.

# 1. Execute
if [ -f "$BIN" ]; then
    "$BIN" vfs-cache "$VAL"
    RET=$?
    if [ $RET -ne 0 ]; then
        echo "LOG: Binary failed (code $RET), falling back to shell..."
        echo "$VAL" > /proc/sys/vm/vfs_cache_pressure || { echo "ERROR: Failed to write to /proc/sys/vm/vfs_cache_pressure"; exit 1; }
    fi
else
    echo "$VAL" > /proc/sys/vm/vfs_cache_pressure || { echo "ERROR: Failed to write to /proc/sys/vm/vfs_cache_pressure"; exit 1; }
fi

# Persistence
if [ $? -eq 0 ] || [ $RET -eq 0 ]; then
    echo "$VAL" > "$DATA_FILE"
fi

exit 0
