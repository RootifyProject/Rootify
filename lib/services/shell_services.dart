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

// ---- SYSTEM ---
import 'dart:io';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ---- LOCAL ---
import '../shell/shell_cpu.dart';
import '../shell/superuser.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// High-performance Execution Engine for Root Shell Interactions
class ShellService {
  // --- Sub
  // Private Logic Containers
  final ShellSession _session;
  String? _rootComplianceCache;
  DateTime? _lastComplianceCheck;

  ShellService(this._session);

  // --- Sub
  // Global Accessors (Delegates to Static Superuser Logic)
  static Future<bool> checkRoot() => Superuser.validateStatus();
  static Future<bool> requestRoot() => Superuser.requestAccess();

  // --- Sub
  // Lifecycle Handlers
  Future<void> warmup() async {}

  Future<void> validateSession() async {
    logger.d("ShellService: Validating shell session...");
    try {
      // Fast ping to ensure shell responsiveness
      final ping = await exec("echo 1", canSkip: false)
          .timeout(const Duration(seconds: 1));
      if (ping.trim() != "1") {
        throw Exception("Shell unresponsive");
      }
      logger.d("ShellService: Session valid");
    } catch (e) {
      logger.e("ShellService: Session broken ($e). Attempting recovery...");
    }
  }

  // --- Sub
  // Execution Control
  Future<String> exec(String cmd, {bool canSkip = false}) async {
    return _session.exec(cmd, canSkip: canSkip);
  }

  void killSession() {
    logger.i("ShellService: Explicitly killing session");
    _session.dispose();
  }

  void dispose() => _session.dispose();

  // --- Sub
  // Specialized Shell Bridge Getters
  CpuShellService getCpuShell() => CpuShellService(_session);

  // --- Sub
  // Root State Discovery Logic
  Future<String?> checkRootCompliance() async {
    // Implement 5-minute cache to avoid spamming "pm list packages"
    if (_rootComplianceCache != null &&
        _lastComplianceCheck != null &&
        DateTime.now().difference(_lastComplianceCheck!) <
            const Duration(minutes: 5)) {
      return _rootComplianceCache;
    }

    logger.d("ShellService: Verifying Root Compliance...");
    try {
      final packages = await exec("pm list packages");
      _lastComplianceCheck = DateTime.now();

      if (packages.contains("io.github.x0eg0.magisk")) {
        logger.w("ShellService: Detected Kitsune Mask (EOL/Unsupported)");
        _rootComplianceCache = "UNSUPPORTED: KITSUNE MASK EOL";
      } else if (packages.contains("com.sukisu.ultra")) {
        logger.w("ShellService: Detected Sukisu (Unsupported)");
        _rootComplianceCache = "UNSUPPORTED: SUKISU USER DETECTED";
      } else {
        _rootComplianceCache = null;
      }
      return _rootComplianceCache;
    } catch (e) {
      logger.e("ShellService: Failed to verify Root Compliance", e);
      return null;
    }
  }

  // ---- MAJOR ---
  // Systemless Persistence Generation Engine
  Future<void> syncBootSettings({
    required bool cpuEnabled,
    required bool cpuDisabled,
    required Map<String, dynamic> cpuSettings,
    required bool zramEnabled,
    required int zramSizeMb,
    String? zramAlgo,
    int? swappiness,
    int? vfsCachePressure,
    required String appVersion,
    required String versionCode,
    required bool layaEnabled,
    required List<String> activeLayaModules,
    required bool thermalEnabled,
    required bool thermalDisabled,
    bool? fpsGoEnabled,
    Map<String, dynamic>? fpsGoSettings,
  }) async {
    logger.i("ShellService: Synchronizing Magisk/KSU boot module...");

    // MAGISK / KERNELSU MODULE ARCHITECTURE
    const moduleDir = "/data/adb/modules/rootify";
    const zigbinPath = "$moduleDir/zigbin"; // The payload script
    const servicePath = "$moduleDir/service.sh"; // The launcher
    const actionPath = "$moduleDir/action.sh"; // The KSU action
    const propPath = "$moduleDir/module.prop";

    // --- Sub
    // 1. Prepare Payload Generation (zigbin)
    final sb = StringBuffer();
    sb.writeln("#!/system/bin/sh");
    sb.writeln("# (c) 2026 Rootify. All rights reserved.");

    // CPU Dynamic Governor & Frequency Persistence
    if (cpuEnabled && !cpuDisabled && cpuSettings.isNotEmpty) {
      cpuSettings.forEach((policy, data) {
        final path = "/sys/devices/system/cpu/cpufreq/$policy";

        bool isSelected(dynamic val) {
          if (val is bool) return val;
          return val.toString().toLowerCase() != 'false';
        }

        if (data['governor'] != null && isSelected(data['selected_gov'])) {
          sb.writeln("echo ${data['governor']} > $path/scaling_governor");
        }
        if (data['min'] != null && isSelected(data['selected_min'])) {
          sb.writeln(
              "echo ${data['min']} > $path/scaling_min_freq && chmod 0644 $path/scaling_min_freq");
        }
        if (data['max'] != null && isSelected(data['selected_max'])) {
          sb.writeln(
              "echo ${data['max']} > $path/scaling_max_freq && chmod 0644 $path/scaling_max_freq");
        }
      });
    }

    // ZRAM & VM Subsystem Tuning
    if (zramEnabled) {
      if (zramSizeMb > 0) {
        sb.writeln("swapoff /dev/block/zram0 2>/dev/null");
        sb.writeln("echo 1 > /sys/block/zram0/reset 2>/dev/null");
        if (zramAlgo != null && zramAlgo.isNotEmpty) {
          sb.writeln(
              "echo '$zramAlgo' > /sys/block/zram0/comp_algorithm 2>/dev/null");
        }
        sb.writeln(
            "echo ${zramSizeMb}M > /sys/block/zram0/disksize 2>/dev/null");
        sb.writeln(
            "mkswap /dev/block/zram0 2>/dev/null && swapon /dev/block/zram0 2>/dev/null");
      }
      if (swappiness != null) {
        sb.writeln("echo $swappiness > /proc/sys/vm/swappiness 2>/dev/null");
      }
      if (vfsCachePressure != null) {
        sb.writeln(
            "echo $vfsCachePressure > /proc/sys/vm/vfs_cache_pressure 2>/dev/null");
      }
    }

    // Thermal Mitigation Overrides
    if (thermalEnabled) {
      if (thermalDisabled) {
        sb.writeln("stop thermal-engine; stop thermald; stop mi_thermald;");
        sb.writeln(
            "for zone in /sys/class/thermal/thermal_zone*; do echo disabled > \$zone/mode; done;");
      } else {
        sb.writeln("start thermal-engine; start thermald;");
      }
    }

    // Background DAEMON Activation
    if (layaEnabled && activeLayaModules.isNotEmpty) {
      for (final module in activeLayaModules) {
        final binPath = "/data/data/com.aby.rootify/files/bin/$module";
        sb.writeln("chmod +x $binPath && nohup $binPath > /dev/null 2>&1 &");
      }
    }

    // MTK/QCOM FPSGO Parameter Injection
    if (fpsGoEnabled == true && fpsGoSettings != null) {
      final path = fpsGoSettings['path'] as String?;
      final rawEnabled = fpsGoSettings['enabled'];
      final enabled = rawEnabled is bool
          ? rawEnabled
          : (rawEnabled.toString().toLowerCase() == 'true');
      final mode = fpsGoSettings['mode'] as String?;

      if (path != null) {
        final val = enabled ? "1" : "0";
        sb.writeln("echo $val > $path/fpsgo_enable 2>/dev/null");
        sb.writeln("echo $val > $path/fbt_enable 2>/dev/null");

        if (fpsGoSettings.containsKey('parameters')) {
          final params = fpsGoSettings['parameters'] as Map<String, dynamic>;
          params.forEach((paramPath, value) {
            sb.writeln("echo $value > $paramPath 2>/dev/null");
          });
        }
        if (mode != null) {
          sb.writeln("echo '$mode' > $path/mode 2>/dev/null");
          sb.writeln("echo '$mode' > $path/profile 2>/dev/null");
        }
      }
    }

    // --- Sub
    // 2. Deployment Logic
    try {
      final tempDir = await getTemporaryDirectory();
      await exec("mkdir -p $moduleDir");

      // Generate module.prop metadata
      final propContent =
          "id=rootify\nname=Rootify\nversion=$appVersion\nversionCode=$versionCode\nauthor=Rootify\ndescription=Systemless Rootify Module for persistent tweaks.";
      final tempProp = File('${tempDir.path}/module.prop');
      await tempProp.writeAsString(propContent);
      await exec("mv -f ${tempProp.path} $propPath");

      // Generate service.sh boot-time launcher
      final serviceContent = '''#!/system/bin/sh
# (c) 2026 Rootify. All rights reserved.
MODDIR=\${0%/*}
chmod +x \$MODDIR/zigbin
chmod +x \$MODDIR/uninstall.sh
while [ "\$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done
if [ -z "\$(pm list packages com.aby.rootify)" ]; then
  sh \$MODDIR/uninstall.sh
  touch \$MODDIR/remove
  exit 0
fi
sh \$MODDIR/zigbin &
''';
      final tempService = File('${tempDir.path}/service.sh');
      await tempService.writeAsString(serviceContent);
      await exec("mv -f ${tempService.path} $servicePath");
      await exec("chmod +x $servicePath");

      // Generate action.sh for KSU manager integration
      const actionContent =
          "#!/system/bin/sh\nam start -n com.aby.rootify/.MainActivity";
      final tempAction = File('${tempDir.path}/action.sh');
      await tempAction.writeAsString(actionContent);
      await exec("mv -f ${tempAction.path} $actionPath");
      await exec("chmod +x $actionPath");

      // Generate uninstall.sh for systemless cleanup
      const uninstallContent = '''#!/system/bin/sh
# (c) 2026 Rootify. All rights reserved.
pkill -f laya-kernel-tuner 2>/dev/null
pkill -f laya-battery-monitor 2>/dev/null
rm -rf /data/data/com.aby.rootify
rm -rf /data/user_de/0/com.aby.rootify
rm -rf /data/local/tmp/rootify*
rm -f /data/adb/laya_persist.log
pm uninstall -k com.aby.rootify 2>/dev/null || true
''';
      const uninstallPath = "$moduleDir/uninstall.sh";
      final tempUninstall = File('${tempDir.path}/uninstall.sh');
      await tempUninstall.writeAsString(uninstallContent);
      await exec("mv -f ${tempUninstall.path} $uninstallPath");
      await exec("chmod +x $uninstallPath");

      // Generate final zigbin binary payload
      final zigbinContent = sb.toString();
      final tempZigbin = File('${tempDir.path}/zigbin');
      await tempZigbin.writeAsString(zigbinContent);
      await exec("mv -f ${tempZigbin.path} $zigbinPath");
      await exec("chmod +x $zigbinPath");

      // Legacy file cleanup and permission enforcement
      await exec("rm -f /data/adb/service.d/rootify_boot.sh");
      await exec("chown -R 0.0 $moduleDir");

      logger.d("RootShell: Magisk Module successfully synced (zigbin).");
    } catch (e) {
      logger.e("RootShell: Failed to sync Magisk Module", e);
    }
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final shellServiceProvider = Provider((ref) {
  final session = ShellSession(); // Singleton Lifecycle
  final service = ShellService(session);
  ref.onDispose(() => session.dispose());
  return service;
});
