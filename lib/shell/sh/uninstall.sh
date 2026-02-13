#!/system/bin/sh
# Rootify Module - Comprehensive Cleanup Script

MODDIR="/data/adb/modules/rootify"

# 1. Trigger Native Reset (Restore Defaults & Stop Services)
if [ -f "$MODDIR/ROOTIFY" ]; then
    chmod +x "$MODDIR/ROOTIFY"
    "$MODDIR/ROOTIFY" reset
fi

# 2. Aggressive Process Termination
pkill -9 -f laya-kernel-tuner 2>/dev/null
pkill -9 -f laya-battery-monitor 2>/dev/null
pkill -9 -f ROOTIFY 2>/dev/null
pkill -f "logcat | grep Laya" 2>/dev/null

# 3. Filesystem Cleanup
rm -rf /data/data/com.aby.rootify 2>/dev/null
rm -rf /data/user_de/0/com.aby.rootify 2>/dev/null
rm -rf /data/local/tmp/rootify* 2>/dev/null
rm -f /data/adb/laya_persist.log 2>/dev/null

# 4. Magisk Module Specifics
rm -rf "$MODDIR" 2>/dev/null

# 5. App Uninstallation
pm uninstall com.aby.rootify 2>/dev/null || true
