/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../shell/base_shell.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Bridge for Thermal Throttling & Safety Management
class ThermalShellService extends BaseShellService {
  ThermalShellService(super.session);

  // --- Sub
  // Throttling Visibility Logic
  Future<bool> getThermalStatus() async {
    logger.d("ThermalShell: Checking thermal throttling status...");
    try {
      // Comment: Check for active vendor thermal daemons in init.svc
      final result = await exec(
          "getprop | grep -E 'init.svc.*thermal' || echo 'stopped'",
          silent: true);
      if (result.contains("running")) {
        return true;
      }

      // Comment: Fallback check for kernel-side thermal zone mode
      final mode = await exec(
          "cat /sys/class/thermal/thermal_zone0/mode 2>/dev/null",
          silent: true);
      final val = mode.toLowerCase().trim();
      return val == 'enabled' || val == '1';
    } catch (e) {
      logger.e("ThermalShell: Status check failed", e);
      return true;
    }
  }

  // --- Sub
  // Aggressive Thermal Controls
  Future<void> disableThermal() async {
    logger.w("ThermalShell: DISABLING THERMAL THROTTLING (Bypassing safety)");
    const shellPath = "/data/adb/modules/rootify/shell";
    await exec("sh $shellPath/THERMAL.sh");
  }

  Future<void> enableThermal() async {
    logger.i("ThermalShell: Restoring default thermal management");
    final services = [
      "thermal-engine",
      "thermald",
      "mi_thermald",
      "thermal_manager",
      "vendor.thermal-engine"
    ];
    StringBuffer cmd = StringBuffer();

    // Comment: 1. Restart Userspace Daemons
    for (var svc in services) {
      cmd.write("start $svc 2>/dev/null; setprop ctl.start $svc 2>/dev/null; ");
    }

    // Comment: 2. Re-enable Kernel Zones
    cmd.write("for zone in /sys/class/thermal/thermal_zone*; do ");
    cmd.write("  echo enabled > \$zone/mode 2>/dev/null; ");
    cmd.write("done; ");

    // Comment: 3. Restart Driver Loops
    cmd.write(
        "echo 1 > /sys/module/msm_thermal/core_control/enabled 2>/dev/null; ");
    cmd.write(
        "echo 1 > /sys/module/msm_thermal/parameters/enabled 2>/dev/null; ");
    cmd.write("echo 1 > /proc/driver/thermal/cl_enable 2>/dev/null; ");

    await exec(cmd.toString());
  }
}

// ---- MAJOR ---
// Global Providers
final thermalShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return ThermalShellService(session);
});
