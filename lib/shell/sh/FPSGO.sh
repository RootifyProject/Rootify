#!/system/bin/sh
#
# MediaTek FPSGO Runtime Tuning Wrapper
# Orchestrates calls to the native FPSGO logic within ROOTIFY with robust logging and fallbacks.

CMD=$1
PATH_OR_PARAM=$2
VALUE=$3

MODULE_DIR="/data/adb/modules/rootify"
BIN="$MODULE_DIR/ROOTIFY"
DATA_FILE="$MODULE_DIR/configs/FPSGO"
LOG_FILE="$MODULE_DIR/logs/fpsgo.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$DATA_FILE")"

# --- Sub
# Logging Helper
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# --- Sub
# Execution Logic
if [ -f "$BIN" ]; then
    # Call internal binary for high-performance sysfs writes
    "$BIN" fpsgo "$CMD" "$PATH_OR_PARAM" "$VALUE" >> "$LOG_FILE" 2>&1
    RET=$?
else
    log "WARN: ROOTIFY binary missing. Using shell fallback for $CMD"
    case "$CMD" in
        enable)
            # Try multiple common enable nodes if path is a directory
            if [ -d "$PATH_OR_PARAM" ]; then
                echo "$VALUE" > "$PATH_OR_PARAM/fpsgo_enable" 2>/dev/null
                echo "$VALUE" > "$PATH_OR_PARAM/fbt_enable" 2>/dev/null
            else
                echo "$VALUE" > "$PATH_OR_PARAM" 2>/dev/null
            fi
            RET=$?
            ;;
        mode)
            echo "$VALUE" > "$PATH_OR_PARAM/mode" 2>/dev/null || echo "$VALUE" > "$PATH_OR_PARAM/profile" 2>/dev/null
            RET=$?
            ;;
        set)
            echo "$VALUE" > "$PATH_OR_PARAM" 2>/dev/null
            RET=$?
            ;;
        *)
            log "ERROR: Unknown FPSGO command: $CMD"
            exit 1
            ;;
    esac
fi

# --- Sub
# Persistence (Optional: App handles most persistence, but we can track for boot)
if [ $RET -eq 0 ]; then
    log "Success: $CMD $PATH_OR_PARAM $VALUE"
else
    log "ERROR: Failed to $CMD $PATH_OR_PARAM (Code $RET)"
fi

exit $RET
