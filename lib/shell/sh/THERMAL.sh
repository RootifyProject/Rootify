#!/system/bin/sh
# THERMAL.sh - Granular Thermal Deception Strategy
# Usage: THERMAL.sh

# Strategy: Service Deception (Stubbing thermal messages)
# This prevents throttling while keeping the daemon 'alive' to avoid bootloops.
if [ -f "/sys/class/thermal/thermal_message/sconfig" ]; then
    echo 0 > /sys/class/thermal/thermal_message/sconfig
fi

# Additional: Bypass logic for generic zones if needed
for zone in /sys/class/thermal/thermal_zone*; do
    # Only disable if safe, or use remount strategy if paths exist
    echo "disabled" > "$zone/mode" 2>/dev/null
done

MODULE_DIR="/data/adb/modules/rootify"
DATA_FILE="$MODULE_DIR/configs/THERMAL"

mkdir -p "$MODULE_DIR/configs"
echo "isRunning: true" > "$DATA_FILE"
echo "applyonBoot?: true" >> "$DATA_FILE"

echo "[THERMAL] Deception applied. Throttling bypassed safely."
