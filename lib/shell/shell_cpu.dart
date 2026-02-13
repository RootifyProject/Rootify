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
import '../utils/app_logger.dart';
import '../shell/base_shell.dart';
import '../shell/shellsession.dart';

// ---- MAJOR ---
// Bridge for CPU Scaling & Load Monitoring
class CpuShellService extends BaseShellService {
  CpuShellService(super.session);

  // --- Sub
  // Topology Discovery Logic
  Future<List<String>> getCpuPolicies() async {
    logger.d("CpuShell: Identifying CPU frequency policies...");
    try {
      final result = await exec("ls -d /sys/devices/system/cpu/cpufreq/policy*",
          silent: true);
      if (result.isEmpty) {
        logger.w("CpuShell: Topology discovery failed (sysfs missing)");
        return [];
      }
      final policies = result.split('\n').where((s) => s.isNotEmpty).toList();
      logger.d("CpuShell: Verified ${policies.length} logical policies");
      return policies;
    } catch (e) {
      logger.e("CpuShell: Topology error", e);
      return [];
    }
  }

  // --- Sub
  // Capability Query Logic
  Future<List<String>> getAvailableGovernors(String policyPath) async {
    logger.d("CpuShell: Scanning governors for $policyPath");
    try {
      final output = await exec("cat $policyPath/scaling_available_governors",
          silent: true);
      final govs = output.split(' ').where((s) => s.isNotEmpty).toList();
      return govs;
    } catch (e) {
      logger.e("CpuShell: Governor fetch error", e);
      return [];
    }
  }

  Future<List<String>> getAvailableFrequencies(String policyPath) async {
    logger.d("CpuShell: Scanning frequency table for $policyPath");
    try {
      final output = await exec("cat $policyPath/scaling_available_frequencies",
          silent: true);
      final freqs = output.split(' ').where((s) => s.isNotEmpty).toList();
      return freqs;
    } catch (e) {
      logger.e("CpuShell: Frequency fetch error", e);
      return [];
    }
  }

  // --- Sub
  // Core Scaling Controls
  Future<String> getGovernor(String policyPath) async {
    final gov = await exec("cat $policyPath/scaling_governor", silent: true);
    return gov.trim();
  }

  Future<void> setGovernor(String policyPath, String governor) async {
    logger.i("CpuShell: setGovernor $policyPath [$governor]");
    final policyNum = policyPath.replaceAll(RegExp(r'.*policy'), '');
    const modPath = "/data/adb/modules/rootify/shell";

    // Detail: Utilize granular CAPSLOCK zigbin wrapper
    await exec("sh $modPath/GOVERNOR.sh $policyNum $governor 2>&1");
  }

  Future<void> setGlobalGovernor(String governor) async {
    logger.i("CpuShell: Global Scaling transition -> [$governor]");

    // Applying to all common policies (0-7 for octa-core)
    for (int i = 0; i < 8; i++) {
      await exec("sh /data/adb/modules/rootify/shell/GOVERNOR.sh $i $governor");
    }
  }

  Future<String> getMinFreq(String policyPath) async {
    final freq = await exec("cat $policyPath/scaling_min_freq", silent: true);
    return freq.trim();
  }

  Future<void> setMinFreq(String policyPath, String freq) async {
    logger.i("CpuShell: setMinFreq [$policyPath] -> $freq");
    final policyNum = policyPath.replaceAll(RegExp(r'.*policy'), '');
    const modPath = "/data/adb/modules/rootify/shell";

    final output = await exec("sh $modPath/MINFREQ.sh $policyNum $freq 2>&1");
    if (output.isNotEmpty) {
      logger.d("CpuShell: MINFREQ output -> $output");
    }
  }

  Future<String> getMaxFreq(String policyPath) async {
    final freq = await exec("cat $policyPath/scaling_max_freq", silent: true);
    return freq.trim();
  }

  Future<void> setMaxFreq(String policyPath, String freq) async {
    logger.i("CpuShell: setMaxFreq [$policyPath] -> $freq");
    final policyNum = policyPath.replaceAll(RegExp(r'.*policy'), '');
    const modPath = "/data/adb/modules/rootify/shell";

    final output = await exec("sh $modPath/MAXFREQ.sh $policyNum $freq 2>&1");
    if (output.isNotEmpty) {
      logger.d("CpuShell: MAXFREQ output -> $output");
    }
  }

  Future<String> getCurrentFreq(String policyPath) async {
    final freq = await exec("cat $policyPath/scaling_cur_freq", silent: true);
    return freq.trim();
  }

  // --- Sub
  // Aggregated Batch Logic
  Future<Map<String, String>> getAllCpuFreqs(List<String> policies) async {
    if (policies.isEmpty) return {};
    try {
      final paths = policies.map((p) => "$p/scaling_cur_freq").join(' ');
      final output = await exec("cat $paths", canSkip: true, silent: true);
      final lines = output.split('\n').where((s) => s.isNotEmpty).toList();
      final Map<String, String> result = {};
      for (int i = 0; i < lines.length && i < policies.length; i++) {
        result[policies[i]] = lines[i].trim();
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // --- Sub
  // Load Analysis Engine
  Future<double> getCpuLoad() async {
    try {
      // Comment: Single-iteration batch mode for performance
      final output = await exec("top -n 1 -b", canSkip: true, silent: true);
      if (output.isEmpty) return 0.0;

      // Comment: Normalize Toybox/Standard distribution formats
      final match = RegExp(r'(\d+)%cpu\s+.*?\s+(\d+)%idle')
          .firstMatch(output.toLowerCase());
      if (match != null) {
        final total = double.tryParse(match.group(1) ?? "100") ?? 100.0;
        final idle = double.tryParse(match.group(2) ?? "100") ?? 100.0;
        if (total > 0) {
          return ((total - idle) / total * 100.0).clamp(0.0, 100.0);
        }
      }

      return 0.0;
    } catch (e) {
      logger.e("CpuShell: CPU load profiling failed", e);
      return 0.0;
    }
  }
}

// ---- MAJOR ---
// Global Providers
final cpuShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return CpuShellService(session);
});
