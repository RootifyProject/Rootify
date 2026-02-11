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
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import 'shared_prefs_provider.dart';
import '../shell/shell_layakertun.dart';
import '../shell/shell_layabattmon.dart';
import '../shell/shell_magisk.dart';
import '../services/shell_services.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Module State Model
class ModuleState {
  // --- Fields
  final bool isLoading;
  final bool isKernelTunerRunning;
  final bool isBatteryMonitorRunning;
  final bool hasKernelTunerModule;
  final bool hasBatteryMonitorModule;
  final bool isKTBootEnabled;
  final bool isBMBootEnabled;
  final bool layaEnabled;
  final List<String> activeLayaModules;
  final int? ktPid;
  final int? bmPid;
  final Map<String, bool> processingAddons;
  final String? errorMessage;

  const ModuleState({
    this.isLoading = false,
    this.isKernelTunerRunning = false,
    this.isBatteryMonitorRunning = false,
    this.hasKernelTunerModule = false,
    this.hasBatteryMonitorModule = false,
    this.isKTBootEnabled = false,
    this.isBMBootEnabled = false,
    this.layaEnabled = false,
    this.activeLayaModules = const [],
    this.ktPid,
    this.bmPid,
    this.processingAddons = const {},
    this.errorMessage,
  });

  // --- Logic
  ModuleState copyWith({
    bool? isLoading,
    bool? isKernelTunerRunning,
    bool? isBatteryMonitorRunning,
    bool? hasKernelTunerModule,
    bool? hasBatteryMonitorModule,
    bool? isKTBootEnabled,
    bool? isBMBootEnabled,
    bool? layaEnabled,
    List<String>? activeLayaModules,
    int? ktPid,
    int? bmPid,
    Map<String, bool>? processingAddons,
    String? errorMessage,
  }) {
    return ModuleState(
      isLoading: isLoading ?? this.isLoading,
      isKernelTunerRunning: isKernelTunerRunning ?? this.isKernelTunerRunning,
      isBatteryMonitorRunning:
          isBatteryMonitorRunning ?? this.isBatteryMonitorRunning,
      hasKernelTunerModule: hasKernelTunerModule ?? this.hasKernelTunerModule,
      hasBatteryMonitorModule:
          hasBatteryMonitorModule ?? this.hasBatteryMonitorModule,
      isKTBootEnabled: isKTBootEnabled ?? this.isKTBootEnabled,
      isBMBootEnabled: isBMBootEnabled ?? this.isBMBootEnabled,
      layaEnabled: layaEnabled ?? this.layaEnabled,
      activeLayaModules: activeLayaModules ?? this.activeLayaModules,
      ktPid: ktPid ?? this.ktPid,
      bmPid: bmPid ?? this.bmPid,
      processingAddons: processingAddons ?? this.processingAddons,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---- MAJOR ---
// Module Notifier Provider
class ModuleNotifier extends Notifier<ModuleState> {
  // --- Services
  late ShellService _shell;
  late LayaKertunShellService _layaKTShell;
  late LayaBattmonShellService _layaBMShell;
  late MagiskShellService _magiskShell;
  late SharedPreferences _prefs;

  // --- Initialization
  @override
  ModuleState build() {
    _shell = ref.watch(shellServiceProvider);
    _layaKTShell = ref.watch(layakertunShellProvider);
    _layaBMShell = ref.watch(layabattmonShellProvider);
    _magiskShell = ref.watch(magiskShellProvider);
    _prefs = ref.watch(sharedPreferencesProvider);

    return ModuleState(
      isKTBootEnabled: _prefs.getBool('laya_kt_boot') ?? false,
      isBMBootEnabled: _prefs.getBool('laya_bm_boot') ?? false,
    );
  }

  // --- Actions
  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Check Root Compliance
      final errorMsg = await _shell.checkRootCompliance();
      if (errorMsg != null) {
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return;
      }

      // 2. Check Running Status and PIDs using specialized logic
      final ktPid = await _layaKTShell.getPID(
          LayaKertunShellService.binKT, LayaKertunShellService.patternKT);
      final bmPid = await _layaBMShell.getPID(
          LayaBattmonShellService.binBM, LayaBattmonShellService.patternBM);

      final ktRunning = ktPid != null;
      final bmRunning = bmPid != null;

      // 3. Check Module Installed
      final hasKT = await _magiskShell.isModuleInstalled("laya_kerneltuner");
      final hasBM = await _magiskShell.isModuleInstalled("battmontester");

      state = state.copyWith(
        isLoading: false,
        isKernelTunerRunning: ktRunning,
        isBatteryMonitorRunning: bmRunning,
        ktPid: ktPid,
        bmPid: bmPid,
        hasKernelTunerModule: hasKT,
        hasBatteryMonitorModule: hasBM,
      );

      // IMPORTANT: Update Prefs if running status changed manually
      await _updateActiveModulesInPrefs();
    } catch (e) {
      logger.e("ModuleProvider: Error loading module status", e);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _updateActiveModulesInPrefs() async {
    final active = <String>[];
    if (state.isKernelTunerRunning) active.add("laya-kernel-tuner");
    if (state.isBatteryMonitorRunning) active.add("laya-battery-monitor");
    await _prefs.setStringList('laya_modules', active);
  }

  Future<void> toggleKTBoot(bool enabled) async {
    logger.i("ModuleProvider: toggleKTBoot -> $enabled");

    if (enabled && !state.isKernelTunerRunning) {
      throw Exception(
          "Please start Kernel Tuner before enabling Apply on Boot.");
    }

    await _prefs.setBool('laya_kt_boot', enabled);
    state = state.copyWith(isKTBootEnabled: enabled);
    await _saveAndSync();
  }

  Future<void> toggleBMBoot(bool enabled) async {
    logger.i("ModuleProvider: toggleBMBoot -> $enabled");

    if (enabled && !state.isBatteryMonitorRunning) {
      throw Exception(
          "Please start Battery Monitor before enabling Apply on Boot.");
    }

    await _prefs.setBool('laya_bm_boot', enabled);
    state = state.copyWith(isBMBootEnabled: enabled);
    await _saveAndSync();
  }

  Future<void> refresh(
      {int retries = 0,
      Duration delay = Duration.zero,
      String? checkAddonId,
      bool? expectRunning}) async {
    if (delay != Duration.zero) await Future.delayed(delay);
    await loadStatus();

    // If retries requested, we loop to catch slow-starting/stopping binaries
    if (retries > 0) {
      for (int i = 0; i < retries; i++) {
        // Break early if condition met
        if (checkAddonId != null && expectRunning != null) {
          final isRunning = checkAddonId == "laya-kernel-tuner"
              ? state.isKernelTunerRunning
              : state.isBatteryMonitorRunning;
          if (isRunning == expectRunning) break;
        }

        await Future.delayed(const Duration(milliseconds: 300));
        await loadStatus();
      }
    }
  }

  Future<void> _saveAndSync() async {
    final info = await PackageInfo.fromPlatform();

    await _shell.syncBootSettings(
      appVersion: info.version,
      versionCode: info.buildNumber,
      cpuEnabled: _prefs.getBool('cpu_boot') ?? false,
      cpuDisabled: !(_prefs.getBool('cpu_boot') ?? false),
      cpuSettings: _getCpuSettings(),
      zramEnabled: _prefs.getBool('perf_zram_enabled') ?? false,
      zramSizeMb: _prefs.getInt('zram_size') ?? 0,
      zramAlgo: _prefs.getString('perf_zram_algo') ?? 'lzo',
      swappiness: _prefs.getInt('swappiness') ?? 60,
      vfsCachePressure: _prefs.getInt('perf_vfs_cache_pressure') ?? 100,
      layaEnabled: state.isKTBootEnabled || state.isBMBootEnabled,
      activeLayaModules: [
        if (state.isKTBootEnabled) "laya-kernel-tuner",
        if (state.isBMBootEnabled) "laya-battery-monitor",
      ],
      thermalEnabled: _prefs.getBool('thermal_boot') ?? false,
      thermalDisabled: _prefs.getBool('thermal_disabled') ?? false,
      fpsGoEnabled: _prefs.getBool('fpsgo_boot') ?? false,
      fpsGoSettings: _getFpsGoSettings(),
    );
  }

  Map<String, dynamic> _getCpuSettings() {
    final str = _prefs.getString('cpu_settings');
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((key, value) {
        return MapEntry(key, Map<String, dynamic>.from(value));
      });
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _getFpsGoSettings() {
    final str = _prefs.getString('fpsgo_settings');
    if (str == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(str));
    } catch (_) {
      return {};
    }
  }

  void setProcessing(String addonId, bool isProcessing) {
    state = state.copyWith(
      processingAddons: {
        ...state.processingAddons,
        addonId: isProcessing,
      },
    );
  }
}

// --- Provider Export
final moduleStateProvider =
    NotifierProvider<ModuleNotifier, ModuleState>(ModuleNotifier.new);
