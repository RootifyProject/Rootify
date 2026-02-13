# Usage: BATTMON.sh

BIN_NAME="laya-battery-monitor"
MODULE_DIR="/data/adb/modules/rootify"
MOD_BIN="$MODULE_DIR/bin/$BIN_NAME"
LOG_FILE="$MODULE_DIR/logs/log-laya-battmon.log"
DATA_FILE="$MODULE_DIR/configs/BATTMON"

EXE="$MOD_BIN"

# 1. Conflict Prevention & Service Isolation
# Kill ANY existing instance and its logcat watcher to prevent overlaps
pkill -9 -f "$BIN_NAME" 2>/dev/null
pkill -f "logcat | grep LayaBatteryMonitor" 2>/dev/null

# Stop system service if active (Hybrid support)
if [ "$(getprop init.svc.laya_battmon)" = "running" ]; then
    stop laya_battmon
fi

if [ "$(getprop init.svc.laya_battmon_svc)" = "running" ]; then
    stop laya_battmon_svc
fi

# Set default property
setprop persist.sys.laya.devide.cpufreq default

# 2. Logging (Logcat)
nohup sh -c "logcat | grep LayaBatteryMonitor" >> "$LOG_FILE" 2>&1 &
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
