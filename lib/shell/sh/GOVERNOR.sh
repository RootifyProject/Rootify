#!/system/bin/sh
#
# Copyright (C) 2026 Rootify - Aby - FoxLabs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Usage: GOVERNOR.sh <cluster> <governor>

CLUSTER=$1
GOVERNOR=$2
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/GOVERNOR"

# Ensure executable (Just in case)
if [ -f "$BIN" ]; then
    chmod +x "$BIN"
fi

# Sysfs Target
GOV_PATH="/sys/devices/system/cpu/cpufreq/policy${CLUSTER}/scaling_governor"

# 1. Try Binary (Fastest) in Module Dir
"$BIN" governor "$CLUSTER" "$GOVERNOR"
RET=$?

# 2. Fallback if Binary Failed (AccessDenied or other)
if [ $RET -ne 0 ]; then
    echo "Binary failed (Code $RET). Fallback to shell write..."
    
    # Force Writable (chmod)
    if [ -f "$GOV_PATH" ]; then
        chmod 644 "$GOV_PATH"
    fi

    echo "$GOVERNOR" > "$GOV_PATH"
    if [ $? -eq 0 ]; then
        RET=0 # Mark as success if fallback worked
        echo "Success: Set GOVERNOR to $GOVERNOR (via Shell)"
    else
        echo "Error: Failed to write to $GOV_PATH (Permission Denied)"
        exit 1
    fi
fi

# 3. Persistence (Save to Data File)
if [ $RET -eq 0 ]; then
    # Ensure data directory exists
    if [ ! -d "$MODULE_DIR/configs" ]; then
        mkdir -p "$MODULE_DIR/configs"
    fi
    
    # Ensure file exists
    if [ ! -f "$DATA_FILE" ]; then
        touch "$DATA_FILE"
    fi

    # Calculate line number (1-based)
    LINE=$((CLUSTER + 1))
    
    # Pad file if it doesn't have enough lines
    CURRENT_LINES=$(wc -l < "$DATA_FILE")
    while [ $CURRENT_LINES -lt $LINE ]; do
        echo "$((CURRENT_LINES)):" >> "$DATA_FILE"
        CURRENT_LINES=$((CURRENT_LINES + 1))
    done

    # Update specific line using sed (Format: CLUSTER:GOVERNOR)
    sed -i "${LINE}s/^[0-7]:.*/$CLUSTER:$GOVERNOR/" "$DATA_FILE"
fi

exit $RET
