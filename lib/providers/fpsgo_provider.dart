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
import '../services/shell_services.dart';
import '../shell/shell_fpsgo.dart';
import 'shared_prefs_provider.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// FPSGo State Model
class FpsGoState {
  // --- Fields
  final bool isLoading;
  final bool isSupported;
  final String? fpsGoPath; // Path to the control node folder
  final bool isEnabled; // Current live status in kernel
  final String currentMode; // e.g., 'default', 'performance', 'gaming'
  final List<String> availableModes; // List of supported modes if available
  final String? errorMessage;
  final bool isApplyOnBootEnabled;
  final bool isPlatformSupported;
  final List<FpsGoParameter> parameters;
  final Map<String, String> parameterValues;
  final Map<String, String> initialValues; // Backup of original system values
  final String? moduleSource; // Added

  const FpsGoState({
    this.isLoading = false,
    this.isSupported = false,
    this.fpsGoPath,
    this.isEnabled = false,
    this.currentMode = 'Unknown',
    this.availableModes = const [],
    this.errorMessage,
    this.isApplyOnBootEnabled = false,
    this.isPlatformSupported = true,
    this.parameters = const [],
    this.parameterValues = const {},
    this.initialValues = const {},
    this.moduleSource,
  });

  // --- Logic
  FpsGoState copyWith({
    bool? isLoading,
    bool? isSupported,
    String? fpsGoPath,
    bool? isEnabled,
    String? currentMode,
    List<String>? availableModes,
    String? errorMessage,
    bool? isApplyOnBootEnabled,
    bool? isPlatformSupported,
    List<FpsGoParameter>? parameters,
    Map<String, String>? parameterValues,
    Map<String, String>? initialValues,
    String? moduleSource,
  }) {
    return FpsGoState(
      isLoading: isLoading ?? this.isLoading,
      isSupported: isSupported ?? this.isSupported,
      fpsGoPath: fpsGoPath ?? this.fpsGoPath,
      isEnabled: isEnabled ?? this.isEnabled,
      currentMode: currentMode ?? this.currentMode,
      availableModes: availableModes ?? this.availableModes,
      errorMessage: errorMessage ?? this.errorMessage,
      isApplyOnBootEnabled: isApplyOnBootEnabled ?? this.isApplyOnBootEnabled,
      isPlatformSupported: isPlatformSupported ?? this.isPlatformSupported,
      parameters: parameters ?? this.parameters,
      parameterValues: parameterValues ?? this.parameterValues,
      initialValues: initialValues ?? this.initialValues,
      moduleSource: moduleSource ?? this.moduleSource,
    );
  }

  // --- Helpers
  // Validates if current state differs from initial/stock
  bool get isModified {
    // 1. Check Mode
    if (currentMode.toLowerCase() != 'default') return true;

    // 2. Check Parameters
    if (initialValues.isEmpty) return false;

    for (final key in parameterValues.keys) {
      if (initialValues.containsKey(key)) {
        if (parameterValues[key] != initialValues[key]) {
          return true;
        }
      }
    }
    return false;
  }
}

// ---- MAJOR ---
// FPSGo Notifier Provider
class FpsGoNotifier extends Notifier<FpsGoState> {
  // --- Services
  late ShellService _shell;
  late FpsGoShellService _fpsGoShell;
  late SharedPreferences _prefs;

  // --- Initialization
  @override
  FpsGoState build() {
    _shell = ref.watch(shellServiceProvider);
    _fpsGoShell = ref.watch(fpsGoShellProvider);
    _prefs = ref.watch(sharedPreferencesProvider);

    final initialValuesStr = _prefs.getString('fpsgo_initial_values');
    Map<String, String> initialValues = {};
    if (initialValuesStr != null) {
      try {
        initialValues = Map<String, String>.from(jsonDecode(initialValuesStr));
      } catch (_) {}
    }

    final settingsStr = _prefs.getString('fpsgo_settings');
    bool isEnabled = false;
    String currentMode = 'Unknown';
    if (settingsStr != null) {
      try {
        final settings = jsonDecode(settingsStr) as Map<String, dynamic>;
        isEnabled =
            settings['enabled'] == 'true' || settings['enabled'] == true;
        currentMode = settings['mode'] ?? 'Unknown';
      } catch (_) {}
    }

    // 0. Check for saved path (Optimization)
    final savedPath = _prefs.getString('fpsgo_path');

    // Initial State
    return FpsGoState(
      isEnabled: isEnabled,
      currentMode: currentMode,
      isApplyOnBootEnabled: _prefs.getBool('fpsgo_boot') ?? false,
      initialValues: initialValues,
      // Pass cached path to avoid rebuild flicker if exists
      fpsGoPath: savedPath,
    );
  }

  // --- Actions
  Future<void> loadData() async {
    if (state.isLoading) return;

    // If already initialized and has parameters, just refresh current values
    if (state.isSupported && state.parameters.isNotEmpty) {
      await _refreshParameterValues();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isSnapdragon = await _fpsGoShell
          .isSnapdragonDevice()
          .timeout(const Duration(seconds: 2));
      if (isSnapdragon) {
        state = state.copyWith(
          isLoading: false,
          isPlatformSupported: false,
          isSupported: false,
        );
        return;
      }

      // 0. Check for saved path (Optimization)
      final savedPath = _prefs.getString('fpsgo_path');
      String? path;

      if (savedPath != null) {
        path = savedPath;
        // Verify it still exists (quick check)
        // If it doesn't exist, we fall back to full scan
      }

      if (path == null) {
        // 1. Full Scan (First Run)
        path = await _fpsGoShell
            .findBestFpsGoPath()
            .timeout(const Duration(seconds: 3));

        if (path != null) {
          await _prefs.setString('fpsgo_path', path);
        }
      }

      if (path == null) {
        state = state.copyWith(
            isLoading: false,
            isSupported: false,
            isPlatformSupported: true,
            errorMessage: "FPSGO module not found.");
        return;
      }

      final results = await Future.wait([
        _fpsGoShell.getFpsGoEnabledStatus(path),
        _fpsGoShell.getFpsGoCurrentMode(path),
        _fpsGoShell.getFpsGoAvailableModes(path)
      ]).timeout(const Duration(seconds: 3));

      final source = path.contains('fbt')
          ? 'FBT'
          : (path.contains('perfmgr') ? 'Unified' : 'Standard');

      // Check for cached parameters
      final cachedIndicesStr = _prefs.getString('fpsgo_available_params');
      List<int>? cachedIndices;
      if (cachedIndicesStr != null) {
        try {
          cachedIndices = (jsonDecode(cachedIndicesStr) as List)
              .map((e) => e as int)
              .toList();
        } catch (_) {}
      }

      final paramResult = await _fpsGoShell
          .getAvailableParameters(cachedIndices: cachedIndices)
          .timeout(const Duration(seconds: 3));

      // If we didn't have cache (or it was invalid), save the new indices
      if (cachedIndices == null || cachedIndices.isEmpty) {
        if (paramResult.indices.isNotEmpty) {
          await _prefs.setString(
              'fpsgo_available_params', jsonEncode(paramResult.indices));
          logger.i(
              "FpsGoProvider: Cached ${paramResult.indices.length} parameter indices.");
        }
      }

      state = state.copyWith(
        isSupported: true,
        fpsGoPath: path,
        isEnabled: results[0] as bool,
        currentMode:
            (results[1] as String).isEmpty ? 'default' : results[1] as String,
        availableModes: results[2] as List<String>,
        parameters: paramResult.params,
        moduleSource: source,
      );

      await _refreshParameterValues().timeout(const Duration(seconds: 3));
    } catch (e) {
      logger.e("FpsGoProvider: loadData Error", e);
      state = state.copyWith(
          isSupported: false,
          errorMessage:
              "Initialization failed or timed out. Check root access.");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // HEAVY: Backup initial system values.
  // Should only be called once during first-run or on-demand.
  Future<void> warmup() async {
    // Ensure data is loaded first (paths/parameters)
    if (!state.isSupported || state.parameters.isEmpty) {
      await loadData();
    }

    if (!state.isSupported || state.parameters.isEmpty) return;
    if (state.initialValues.isNotEmpty) return; // Skip if already have backup

    logger.i("FpsGoProvider: Starting heavy warm-up (Parameter Backup)...");

    final backupValues = await _fpsGoShell.getMultipleParameterValues(
        state.parameters.map((p) => p.path).toList());

    await _prefs.setString('fpsgo_initial_values', jsonEncode(backupValues));
    state = state.copyWith(initialValues: backupValues);
    logger.i(
        "FpsGoProvider: Warm-up complete (${backupValues.length} parameters).");
  }

  // Toggle FPSGO On/Off live.
  Future<void> toggleFpsGo(bool enable) async {
    if (!state.isSupported || state.fpsGoPath == null) return;
    logger.d("FpsGoProvider: Toggling FPSGO status to $enable");

    final previousState = state.isEnabled;
    state = state.copyWith(isEnabled: enable);

    try {
      await _fpsGoShell.setFpsGoStatus(state.fpsGoPath!, enable);
      final confirmedStatus =
          await _fpsGoShell.getFpsGoEnabledStatus(state.fpsGoPath!);
      state = state.copyWith(isEnabled: confirmedStatus);
      await _saveSettingsAndSync();

      if (confirmedStatus) {
        await setMode(state.currentMode);
        logger.i("FPSGO module enabled and profile re-applied");
      } else {
        logger.i("FPSGO module disabled");
      }
    } catch (e, st) {
      logger.e("Failed to toggle FPSGO status", e, st);
      state = state.copyWith(isEnabled: previousState);
      rethrow;
    }
  }

  // Update a single granular parameter
  Future<void> setParameter(String path, String value) async {
    logger.d("FpsGoProvider: setParameter -> $path = $value");
    try {
      await _fpsGoShell.setParameterValue(path, value);

      final newValues = Map<String, String>.from(state.parameterValues);
      newValues[path] = value;

      // User Logic: Auto-switch to UserSpace on manual edit
      String newMode = state.currentMode;
      if (state.currentMode != 'userspace') {
        newMode = 'userspace';
      }

      state = state.copyWith(
        parameterValues: newValues,
        currentMode: newMode,
      );

      await _saveSettingsAndSync();
      logger.i("FPSGO parameter updated: ${path.split('/').last} -> $value");
    } catch (e, st) {
      logger.e("Failed to update FPSGO parameter", e, st);
      rethrow;
    }
  }

  // Change FPSGO Profile/Mode live.
  Future<void> setMode(String profile) async {
    if (!state.isSupported || state.fpsGoPath == null) return;
    logger.d("FpsGoProvider: Applying profile -> $profile");

    state = state.copyWith(currentMode: profile);

    try {
      String kernelMode = "default";

      switch (profile.toLowerCase()) {
        case 'performance':
        case 'gaming':
        case 'drivers':
        case 'recommended':
          kernelMode = "performance";
          break;
        case 'balance':
        case 'balanced':
        case 'userspace':
        default:
          kernelMode = "default";
      }

      if (!state.availableModes.contains(kernelMode) &&
          state.availableModes.contains("gaming")) {
        if (kernelMode == "performance") kernelMode = "gaming";
      }
      await _fpsGoShell.setFpsGoMode(state.fpsGoPath!, kernelMode);

      await _fpsGoShell.applyFpsGoProfile(
        profile,
        state.parameters,
        dynamicValues:
            profile.toLowerCase() == 'default' ? state.initialValues : null,
      );

      final current = await _fpsGoShell.getFpsGoCurrentMode(state.fpsGoPath!);
      logger.i("FPSGO Profile applied: $profile (Kernel: $current)");
      await _refreshParameterValues();
      await _saveSettingsAndSync();
    } catch (e, st) {
      logger.e("Failed to apply FPSGO profile: $profile", e, st);
      rethrow;
    }
  }

  Future<void> _refreshParameterValues() async {
    final values = await _fpsGoShell.getMultipleParameterValues(
        state.parameters.map((p) => p.path).toList());
    state = state.copyWith(parameterValues: values);
  }

  Future<void> toggleApplyOnBoot(bool enabled) async {
    logger.i("FpsGoProvider: toggleApplyOnBoot -> $enabled");

    if (enabled && !state.isModified) {
      throw Exception(
          "Please configure FPSGo settings before enabling Apply on Boot.");
    }

    await _prefs.setBool('fpsgo_boot', enabled);
    state = state.copyWith(isApplyOnBootEnabled: enabled);
    await _saveSettingsAndSync();
  }

  // --- Internal Consistency Actions
  // Persist settings to JSON and regenerate boot script.
  Future<void> _saveSettingsAndSync() async {
    if (!state.isSupported) return;

    final settings = {
      'enabled': state.isEnabled,
      'mode': state.currentMode,
      'path': state.fpsGoPath,
      'parameters': state.parameterValues, // Critical: Save actual values
    };

    await _prefs.setString('fpsgo_settings', jsonEncode(settings));

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
      layaEnabled: _prefs.getBool('laya_boot') ?? false,
      activeLayaModules: _prefs.getStringList('laya_modules') ?? [],
      thermalEnabled: _prefs.getBool('thermal_boot') ?? false,
      thermalDisabled: _prefs.getBool('thermal_disabled') ?? false,
      fpsGoEnabled: state.isApplyOnBootEnabled,
      fpsGoSettings: settings,
    );
  }

  Map<String, Map<String, String>> _getCpuSettings() {
    final str = _prefs.getString('cpu_settings');
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((key, value) {
        return MapEntry(key, Map<String, String>.from(value));
      });
    } catch (_) {
      return {};
    }
  }
}

// --- Provider Export
final fpsGoStateProvider =
    NotifierProvider<FpsGoNotifier, FpsGoState>(FpsGoNotifier.new);
