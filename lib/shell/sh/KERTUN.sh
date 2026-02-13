# Usage: KERTUN.sh

BIN_NAME="laya-kernel-tuner"
MODULE_DIR="/data/adb/modules/rootify"
MOD_BIN="$MODULE_DIR/bin/$BIN_NAME"
LOG_FILE="$MODULE_DIR/logs/log-laya-kertun.log"
DATA_FILE="$MODULE_DIR/configs/KERTUN"

EXE="$MOD_BIN"

# 1. Conflict Prevention & Service Isolation
# Kill ANY existing instance and its logcat watcher to prevent overlaps
pkill -9 -f "$BIN_NAME" 2>/dev/null
pkill -f "logcat | grep LayaKernelTuner" 2>/dev/null

# 2. Logging (Logcat)
nohup sh -c "logcat | grep LayaKernelTuner" >> "$LOG_FILE" 2>&1 &
LOG_PID=$!

# Ensure executable
if [ -f "$EXE" ]; then
    chmod +x "$EXE"
    
    # 3. Start Service
    nohup "$EXE" > /dev/null 2>&1 &
    PID=$!
    
    # 4. Persistence
    if [ -n "$PID" ]; then
        mkdir -p "$MODULE_DIR/configs"
        echo "isRunning: true" > "$DATA_FILE"
        echo "pid: $PID" >> "$DATA_FILE"
        echo "log_pid: $LOG_PID" >> "$DATA_FILE"
        echo "applyonBoot?: true" >> "$DATA_FILE"
    fi
fi
