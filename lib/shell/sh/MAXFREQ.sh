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

# Usage: MAXFREQ.sh <cluster> <freq>

CLUSTER=$1
FREQ=$2
MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/MAXFREQ"

# 1. Execution (Apply to Sysfs)
# Ensure executable
if [ -f "$BIN" ]; then
    chmod +x "$BIN"
fi

# Run binary
"$BIN" maxfreq "$CLUSTER" "$FREQ"
RET=$?

# 2. Persistence (Save to Data File)
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

    # Update specific line using sed (Format: CLUSTER:FREQ)
    sed -i "${LINE}s/^[0-7]:.*/$CLUSTER:$FREQ/" "$DATA_FILE"
    
    # If sed failed (e.g. line was empty/malformed), force it
    # But padding above ensures it exists.
fi

exit $RET
