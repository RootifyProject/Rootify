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
import '../shell/shell_cpu.dart';
import '../shell/superuser.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';
import '../shell/shell_magisk.dart';
import '../providers/rootify_module_provider.dart';

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
  Future<void> warmup() async {
    logger.i("ShellService: Warming up hardware abstraction layer...");

    // 1. Check if module residency is already established and up-to-date
    final magisk = MagiskShellService(_session);
    final hasRT = await magisk.isModuleInstalled("rootify");

    // Perform extraction and deployment ONLY if module is missing
    // Detailed sync (outdated check) is handled by AddonsProvider -> buildAndSync
    if (!hasRT) {
      logger.i("ShellService: Module not found. Initializing residency...");
      await RootifyModuleBuilder.extractAssets();
      await _deployToModule();
      await _fixPermissions();
    } else {
      logger.d(
          "ShellService: Module residency verified. Skipping redundant hot-warmup.");
    }
  }

  Future<void> _deployToModule() async {
    logger.d("ShellService: Deploying assets to module directory...");
    const String moduleBin = "/data/adb/modules/rootify/bin/";
    const String moduleShell = "/data/adb/modules/rootify/shell/";
    const String internalBin = "/data/data/com.aby.rootify/files/bin";
    const String internalShell = "/data/data/com.aby.rootify/files/shell";

    try {
      // Ensure module bin and shell directories exist
      await exec("mkdir -p $moduleBin");
      await exec("mkdir -p $moduleShell");

      // 1. Surgical Deployment
      // Copy Binaries -> Module Bin
      await exec("cp -f $internalBin/* $moduleBin");
      // Copy Scripts -> Module Shell
      await exec("cp -f $internalShell/* $moduleShell");

      // 2. Cleanup Redundant files (remove .sh from bin)
      await exec("rm -f $moduleBin/*.sh", canSkip: true);

      logger.d("ShellService: Deployment completed surgically.");
    } catch (e) {
      logger.e("ShellService: Failed to deploy assets to module", e);
    }
  }

  Future<void> _fixPermissions() async {
    logger.d("ShellService: Fixing permissions...");
    try {
      // 1. Binaries (Execute) - strictly on module path
      await exec("chmod -R 755 /data/adb/modules/rootify/bin/");

      // 2. Sysfs Nodes (Write)
      await exec(
          "chmod 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_min_freq",
          canSkip: true);
      await exec(
          "chmod 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq",
          canSkip: true);
      await exec(
          "chmod 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_governor",
          canSkip: true);
    } catch (e) {
      logger.w("ShellService: Permission fix warning (non-fatal): $e");
    }
  }

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
  // Systemless Persistence Generation Engine (Delegated to ModuleBuilder)
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
    // Detail: Centralized module construction logic moved to RootifyModuleBuilder
    // This method now serves as the entry point that provides shell access to the builder.
    await RootifyModuleBuilder.buildAndSync(
      this,
      cpuEnabled: cpuEnabled,
      cpuDisabled: cpuDisabled,
      cpuSettings: cpuSettings,
      zramEnabled: zramEnabled,
      zramSizeMb: zramSizeMb,
      zramAlgo: zramAlgo,
      swappiness: swappiness,
      vfsCachePressure: vfsCachePressure,
      appVersion: appVersion,
      versionCode: versionCode,
      layaEnabled: layaEnabled,
      activeLayaModules: activeLayaModules,
      thermalEnabled: thermalEnabled,
      thermalDisabled: thermalDisabled,
      fpsGoEnabled: fpsGoEnabled,
      fpsGoSettings: fpsGoSettings,
    );
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
