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
// FPSGO / Frame Boost Configuration Models
enum FpsGoParamType { toggle, number, range }

class FpsGoParameter {
  final String id;
  final String category;
  final String name;
  final String path;
  final String description;
  final FpsGoParamType type;
  final double? min;
  final double? max;
  final List<String>? options;
  final Map<String, String>? values;

  const FpsGoParameter(
      this.id, this.category, this.name, this.path, this.description,
      {this.type = FpsGoParamType.toggle,
      this.min,
      this.max,
      this.options,
      this.values});

  // --- Sub
  // Classification Catalog (Kernel-specific Nodes)
  static const List<FpsGoParameter> defaults = [
    // Comment: FBT (Frame Boost) Subsystem
    FpsGoParameter(
      "fbt_boost_ta",
      "FBT",
      "Boost Touch Accelerator",
      "/sys/kernel/fpsgo/fbt/boost_ta",
      "Boosts CPU/GPU frequency immediately upon touch events to reduce input lag.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_switch_down",
      "FBT",
      "Switch Down Throttle",
      "/sys/kernel/fpsgo/fbt/enable_switch_down_throttle",
      "Enables throttling down frequency faster when switching between heavy and light tasks.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fbt_boost_vip",
      "FBT",
      "VIP Boost",
      "/sys/kernel/fpsgo/fbt/boost_VIP",
      "Prioritizes tasks for foreground application performance.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_llf_policy",
      "FBT",
      "LLF Task Policy",
      "/sys/kernel/fpsgo/fbt/llf_task_policy",
      "Scheduling policy for low-intensity frames.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '0',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_uclamp_boost",
      "FBT",
      "UClamp Boost",
      "/sys/kernel/fpsgo/fbt/enable_uclamp_boost",
      "Uses Utilization Clamping to hint minimal performance requirements.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fbt_thrm_enable",
      "FBT",
      "Internal Thermal Logic",
      "/sys/kernel/fpsgo/fbt/thrm_enable",
      "Main switch for FPSGO internal thermal management.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_thrm_limit_cpu",
      "FBT",
      "Thermal Limit CPU",
      "/sys/kernel/fpsgo/fbt/thrm_limit_cpu",
      "Limits CPU frequency to prevent overheating.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fbt_thrm_temp_th",
      "FBT",
      "Thermal Temp Threshold",
      "/sys/kernel/fpsgo/fbt/thrm_temp_th",
      "Sets the temperature threshold for thermal throttling.",
      type: FpsGoParamType.number,
      values: {
        'balanced': '1',
        'recommended': '0',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_light_load",
      "FBT",
      "Light Load Policy",
      "/sys/kernel/fpsgo/fbt/light_loading_policy",
      "Controls power saving behavior during low-intensity scenes.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '0',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fbt_ultra_rescue",
      "FBT",
      "Ultra Rescue",
      "/sys/kernel/fpsgo/fbt/ultra_rescue",
      "Emergency performance boost when frames drop below critical levels.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),

    // Comment: FSTB (Frame Stabilizer) Subsystem
    FpsGoParameter(
      "fstb_adopt_low_fps",
      "FSTB",
      "Adopt Low FPS",
      "/sys/kernel/fpsgo/fstb/adopt_low_fps",
      "Adapts scheduling strategy for low frame rate games.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_self_ctrl",
      "FSTB",
      "Self Control FPS",
      "/sys/kernel/fpsgo/fstb/fstb_self_ctrl_fps_enable",
      "Allows Frame Stabilizer to regulate target FPS dynamically.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_boost_ta",
      "FSTB",
      "FSTB Boost",
      "/sys/kernel/fpsgo/fstb/boost_ta",
      "Touch boost specifically for the Frame Stabilizer module.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "fstb_switch_sync",
      "FSTB",
      "Switch Sync Flag",
      "/sys/kernel/fpsgo/fstb/enable_switch_sync_flag",
      "Synchronizes frame switches to prevent tearing.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_gpu_slowdown",
      "FSTB",
      "GPU Slowdown Check",
      "/sys/kernel/fpsgo/fstb/gpu_slowdown_check",
      "Monitors GPU load to prevent frame drops.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_powerhal_enable",
      "FSTB",
      "PowerHAL Integration",
      "/sys/kernel/fpsgo/fstb/tfps_to_powerhal_enable",
      "Enables frame rate signaling to the device Power HAL.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_margin_mode",
      "FSTB",
      "Frame Margin Mode",
      "/sys/kernel/fpsgo/fstb/margin_mode",
      "Sets aggression level for stabilization margins.",
      type: FpsGoParamType.number,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "fstb_margin_gpu",
      "FSTB",
      "GPU Margin Mode",
      "/sys/kernel/fpsgo/fstb/margin_mode_gpu",
      "Sets the GPU-specific margin for stabilization.",
      type: FpsGoParamType.number,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),

    // Comment: Kernel / MTK Discovery Nodes
    FpsGoParameter(
      "mtk_uboost_enhance",
      "Kernel",
      "UBoost Enhance",
      "/sys/module/mtk_fpsgo/parameters/uboost_enhance_f",
      "Scaling factor for UBoost hold aggression.",
      type: FpsGoParamType.range,
      min: 0,
      max: 200,
      values: {
        'balanced': '0',
        'recommended': '100',
        'performance': '100',
      },
    ),
    FpsGoParameter(
      "mtk_isolation_cap",
      "Kernel",
      "Isolation Limit Cap",
      "/sys/module/mtk_fpsgo/parameters/isolation_limit_cap",
      "Caps big core isolation to maintain performance.",
      type: FpsGoParamType.number,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '0',
      },
    ),
    FpsGoParameter(
      "mtk_gcc_enable",
      "Kernel",
      "GCC Scheduler Boost",
      "/sys/module/mtk_fpsgo/parameters/gcc_enable",
      "Enables scheduler optimizations for frame delivery.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "mtk_loading_enable",
      "Kernel",
      "Loading Optimization",
      "/sys/module/mtk_fpsgo/parameters/loading_enable",
      "Optimizations for scene loading transitions.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "mtk_qr_enable",
      "Kernel",
      "Quota Regulator",
      "/sys/module/mtk_fpsgo/parameters/qr_enable",
      "Regulates CPU quota based on frame demand.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "mtk_rescue_enhance",
      "Kernel",
      "Rescue Enhancement",
      "/sys/module/mtk_fpsgo/parameters/rescue_enhance_f",
      "Weight factor for ultra rescue perf injection.",
      type: FpsGoParamType.range,
      min: 0,
      max: 100,
      values: {
        'balanced': '0',
        'recommended': '50',
        'performance': '100',
      },
    ),
    FpsGoParameter(
      "mtk_rescue_percent",
      "Kernel",
      "Rescue Threshold %",
      "/sys/module/mtk_fpsgo/parameters/rescue_percent",
      "Threshold at which emergency performance triggers.",
      type: FpsGoParamType.range,
      min: 0,
      max: 100,
      values: {
        'balanced': '50',
        'recommended': '30',
        'performance': '10',
      },
    ),

    // Comment: PNP & GED Coordination
    FpsGoParameter(
      "pnp_boost_enable",
      "PNP",
      "PNP Boost Enable",
      "/sys/pnpmgr/fpsgo_boost/boost_enable",
      "Main switch for Power & Performance boost coordinator.",
      type: FpsGoParamType.toggle,
      values: {
        'balanced': '1',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "pnp_boost_mode",
      "PNP",
      "PNP Boost Mode",
      "/sys/pnpmgr/fpsgo_boost/boost_mode",
      "0 = Power Save, 1 = Performance, 2 = Ultra.",
      type: FpsGoParamType.number,
      values: {
        'balanced': '0',
        'recommended': '1',
        'performance': '1',
      },
    ),
    FpsGoParameter(
      "ged_gpu_boost",
      "GED",
      "GED GPU Boost",
      "/sys/kernel/ged/hal/gpu_boost_level",
      "Direct GPU frequency floor adjustment.",
      type: FpsGoParamType.range,
      min: 0,
      max: 100,
      values: {
        'balanced': '0',
        'recommended': '50',
        'performance': '100',
      },
    ),
  ];
}

// ---- MAJOR ---
// Bridge for MediaTek FPSGO Runtime Tuning
class FpsGoShellService extends BaseShellService {
  FpsGoShellService(super.session);

  String? _cachedFpsGoPath;

  // --- Sub
  // Node Discovery Engine
  Future<List<String>> scanAllFpsGoPaths() async {
    logger.d("FpsGoShell: Scanning systemic FPSGO nodes...");

    final candidates = [
      "/sys/kernel/fpsgo/common",
      "/sys/kernel/fpsgo/fbt",
      "/sys/kernel/fpsgo",
      "/sys/module/perfmgr/parameters",
      "/sys/module/perfmgr_fpsgo/parameters",
      "/sys/module/mtk_fpsgo/parameters",
      "/sys/module/fpsgo/parameters",
      "/sys/module/fbt_cpu/parameters",
      "/proc/perfmgr/fpsgo",
      "/sys/power/perfmgr/fpsgo",
    ];

    final foundPaths = <String>[];

    for (final path in candidates) {
      final check = await exec(
          "test -d $path && (test -f $path/fpsgo_enable -o -f $path/fbt_enable -o -f $path/mode -o -f $path/enabled) && echo 'YES' || echo 'NO'",
          silent: true);
      if (check.contains("YES")) {
        foundPaths.add(path);
      }
    }
    return foundPaths;
  }

  Future<String?> findBestFpsGoPath() async {
    if (_cachedFpsGoPath != null) return _cachedFpsGoPath;

    final allPaths = await scanAllFpsGoPaths();
    if (allPaths.isEmpty) return null;

    // Comment: Priority selection prioritizes common/fbt nodes
    final common =
        allPaths.firstWhere((p) => p.contains("/common"), orElse: () => "");
    if (common.isNotEmpty) return _cachedFpsGoPath = common;

    final fbt =
        allPaths.firstWhere((p) => p.contains("/fbt"), orElse: () => "");
    if (fbt.isNotEmpty) return _cachedFpsGoPath = fbt;

    return _cachedFpsGoPath = allPaths.first;
  }

  // Comment: RESTORED - Required for hardware identification
  Future<bool> isSnapdragonDevice() async {
    try {
      final platform =
          (await exec("getprop ro.board.platform", silent: true)).toLowerCase();
      final board =
          (await exec("getprop ro.product.board", silent: true)).toLowerCase();
      final soc =
          (await exec("getprop ro.soc.model", silent: true)).toLowerCase();

      return platform.contains("msm") ||
          platform.contains("sdm") ||
          platform.contains("sm") ||
          platform.contains("qcom") ||
          board.contains("msm") ||
          board.contains("qcom") ||
          soc.contains("sm") ||
          soc.contains("snapdragon");
    } catch (_) {
      return false;
    }
  }

  // --- Sub
  // Runtime State Controls
  Future<bool> getFpsGoEnabledStatus(String path) async {
    try {
      final output = await exec(
          "cat $path/fpsgo_enable 2>/dev/null || "
          "cat $path/fbt_enable 2>/dev/null || "
          "cat $path/enabled 2>/dev/null",
          silent: true);
      return (int.tryParse(output.trim()) ?? 0) == 1;
    } catch (e) {
      return false;
    }
  }

  Future<void> setFpsGoStatus(String path, bool enable) async {
    final val = enable ? "1" : "0";
    logger.i("FpsGoShell: Scaling transition -> $enable");
    // Use Shell Wrapper for robustness (logging/fallback)
    await exec("sh /data/adb/modules/rootify/shell/FPSGO.sh enable $path $val");
  }

  // Comment: RESTORED - Required for mode switching
  Future<String> getFpsGoCurrentMode(String path) async {
    try {
      final output = await exec(
          "cat $path/mode 2>/dev/null || cat $path/profile 2>/dev/null",
          silent: true);
      final mode = output.trim();
      return mode.isEmpty || mode.toLowerCase().contains("cat:")
          ? "default"
          : mode;
    } catch (_) {
      return "default";
    }
  }

  // Comment: RESTORED - Required for capability discovery
  Future<List<String>> getFpsGoAvailableModes(String path) async {
    try {
      final output =
          await exec("cat $path/available_modes 2>/dev/null", silent: true);
      if (output.isNotEmpty) {
        return output.split(' ').where((s) => s.trim().isNotEmpty).toList();
      }
      // Fallback for nodes that support mode but don't list them
      final hasModeNode =
          (await exec("test -f $path/mode && echo 'YES'", silent: true))
              .contains("YES");
      return hasModeNode ? ["default", "performance", "powersave"] : [];
    } catch (_) {
      return [];
    }
  }

  // Comment: RESTORED - Required for mode switching
  Future<void> setFpsGoMode(String path, String mode) async {
    logger.i("FpsGoShell: Mode update -> $mode");
    // Use Shell Wrapper for robustness
    await exec(
        "sh /data/adb/modules/rootify/shell/FPSGO.sh mode $path '$mode'");
  }

  // --- Sub
  // Profile Orchestration
  Future<void> applyFpsGoProfile(
      String profileName, List<FpsGoParameter> availableParams,
      {Map<String, String>? dynamicValues}) async {
    logger.i("FpsGoShell: Profile Injection -> $profileName");

    if (profileName.toLowerCase() == 'userspace') return;

    final commands = <String>[];
    final targetProfile = profileName.toLowerCase() == 'gaming'
        ? 'performance'
        : profileName.toLowerCase();

    for (final param in availableParams) {
      String? val;
      if (targetProfile == 'default' && dynamicValues != null) {
        val = dynamicValues[param.path];
      } else {
        val = param.values?[targetProfile];
      }

      if (val != null) {
        // Use Shell Wrapper for robust granular tuning
        commands.add(
            "sh /data/adb/modules/rootify/shell/FPSGO.sh set ${param.path} '$val'");
      }
    }

    if (commands.isNotEmpty) {
      await exec(commands.join("; "));
    }
  }

  // --- Sub
  // Tunable Query Engine
  Future<({List<FpsGoParameter> params, List<int> indices})>
      getAvailableParameters({List<int>? cachedIndices}) async {
    final List<FpsGoParameter> available = [];
    final List<int> validIndices = [];
    final defaults = FpsGoParameter.defaults;

    if (cachedIndices != null && cachedIndices.isNotEmpty) {
      for (final idx in cachedIndices) {
        if (idx >= 0 && idx < defaults.length) {
          available.add(defaults[idx]);
          validIndices.add(idx);
        }
      }
      return (params: available, indices: validIndices);
    }

    // Comment: Parallel existence verification across sysfs
    List<String> checks = [];
    for (int i = 0; i < defaults.length; i++) {
      checks.add("test -f ${defaults[i].path} && echo '$i'");
    }

    try {
      final output = await exec(checks.join("; "), silent: true);
      final indices = output
          .split('\n')
          .where((s) => s.isNotEmpty)
          .map(int.tryParse)
          .whereType<int>()
          .toList();
      for (final idx in indices) {
        if (idx >= 0 && idx < defaults.length) {
          available.add(defaults[idx]);
          validIndices.add(idx);
        }
      }
    } catch (_) {}

    return (params: available, indices: validIndices);
  }

  // Comment: RESTORED - Required for custom tuning
  Future<void> setParameterValue(String path, String value) async {
    logger.i("FpsGoShell: Tunable update -> $path = $value");
    // Use Shell Wrapper for individual tuning
    await exec(
        "sh /data/adb/modules/rootify/shell/FPSGO.sh set $path '$value'");
  }

  Future<Map<String, String>> getMultipleParameterValues(
      List<String> paths) async {
    if (paths.isEmpty) return {};
    final Map<String, String> results = {};
    const String separator = "|||";
    final List<String> commands =
        paths.map((p) => "cat $p 2>/dev/null || echo ''").toList();

    try {
      final batchedCmd = commands.join("; echo '$separator'; ");
      final output = await exec(batchedCmd, silent: true);
      final values = output.split(separator).map((s) => s.trim()).toList();

      for (int i = 0; i < paths.length; i++) {
        if (i < values.length) results[paths[i]] = values[i];
      }
    } catch (_) {}
    return results;
  }
}

// ---- MAJOR ---
// Global Providers
final fpsGoShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return FpsGoShellService(session);
});
