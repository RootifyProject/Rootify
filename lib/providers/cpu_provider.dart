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

// ---- EXTERNAL ---
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- LOCAL ---
import 'shared_prefs_provider.dart';
import '../services/shell_services.dart';
import '../shell/shell_cpu.dart';
import '../services/cpu.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// CPU Data State
class CpuState {
  // --- Fields
  final bool isLoading;
  final List<String> policies;
  final Map<String, List<String>> availableGovernors;
  final Map<String, List<String>> availableFrequencies;
  final Map<String, String> currentGovernors;
  final Map<String, String> minFreqs;
  final Map<String, String> maxFreqs;
  final Map<String, String> currentFreqs;
  final bool isApplyOnBootEnabled;

  // Selection States (Boot Logic)
  final Map<String, bool> selectedGovernors;
  final Map<String, bool> selectedMinFreqs;
  final Map<String, bool> selectedMaxFreqs;

  // Initial State Cache
  final Map<String, String> initialGovernors;
  final Map<String, String> initialMinFreqs;
  final Map<String, String> initialMaxFreqs;

  CpuState({
    this.isLoading = true,
    this.policies = const [],
    this.availableGovernors = const {},
    this.availableFrequencies = const {},
    this.currentGovernors = const {},
    this.minFreqs = const {},
    this.maxFreqs = const {},
    this.currentFreqs = const {},
    this.isApplyOnBootEnabled = false,
    this.initialGovernors = const {},
    this.initialMinFreqs = const {},
    this.initialMaxFreqs = const {},
    this.selectedGovernors = const {},
    this.selectedMinFreqs = const {},
    this.selectedMaxFreqs = const {},
  });

  // --- Logic
  CpuState copyWith({
    bool? isLoading,
    List<String>? policies,
    Map<String, List<String>>? availableGovernors,
    Map<String, List<String>>? availableFrequencies,
    Map<String, String>? currentGovernors,
    Map<String, String>? minFreqs,
    Map<String, String>? maxFreqs,
    Map<String, String>? currentFreqs,
    bool? isApplyOnBootEnabled,
    Map<String, String>? initialGovernors,
    Map<String, String>? initialMinFreqs,
    Map<String, String>? initialMaxFreqs,
    Map<String, bool>? selectedGovernors,
    Map<String, bool>? selectedMinFreqs,
    Map<String, bool>? selectedMaxFreqs,
  }) {
    return CpuState(
      isLoading: isLoading ?? this.isLoading,
      policies: policies ?? this.policies,
      availableGovernors: availableGovernors ?? this.availableGovernors,
      availableFrequencies: availableFrequencies ?? this.availableFrequencies,
      currentGovernors: currentGovernors ?? this.currentGovernors,
      minFreqs: minFreqs ?? this.minFreqs,
      maxFreqs: maxFreqs ?? this.maxFreqs,
      currentFreqs: currentFreqs ?? this.currentFreqs,
      isApplyOnBootEnabled: isApplyOnBootEnabled ?? this.isApplyOnBootEnabled,
      initialGovernors: initialGovernors ?? this.initialGovernors,
      initialMinFreqs: initialMinFreqs ?? this.initialMinFreqs,
      initialMaxFreqs: initialMaxFreqs ?? this.initialMaxFreqs,
      selectedGovernors: selectedGovernors ?? this.selectedGovernors,
      selectedMinFreqs: selectedMinFreqs ?? this.selectedMinFreqs,
      selectedMaxFreqs: selectedMaxFreqs ?? this.selectedMaxFreqs,
    );
  }

  // --- Helpers
  // Checks for modifications against initial state
  bool get isModified {
    if (policies.isEmpty) return false;

    for (final policy in policies) {
      if (currentGovernors[policy] != initialGovernors[policy]) return true;
      if (minFreqs[policy] != initialMinFreqs[policy]) return true;
      if (maxFreqs[policy] != initialMaxFreqs[policy]) return true;
    }
    return false;
  }
}

// ---- MAJOR ---
// CPU Notifier Provider
class CpuNotifier extends Notifier<CpuState> {
  // --- Services
  late ShellService _shell;
  late CpuShellService _cpuShell;
  late SharedPreferences _prefs;

  // --- Initialization
  @override
  CpuState build() {
    _shell = ref.watch(shellServiceProvider);
    _cpuShell = ref.watch(cpuShellProvider);
    _prefs = ref.watch(sharedPreferencesProvider);

    // Load cached hardware info for instant UI
    final cachedInfoStr = _prefs.getString('initial_cpu_info');
    List<String> policies = [];
    Map<String, List<String>> availableGovernors = {};
    Map<String, List<String>> availableFrequencies = {};

    if (cachedInfoStr != null) {
      try {
        final decoded = jsonDecode(cachedInfoStr) as Map<String, dynamic>;
        policies = List<String>.from(decoded['policies'] ?? []);
        availableGovernors = (decoded['governors'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        );
        availableFrequencies =
            (decoded['frequencies'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        );
      } catch (_) {}
    }

    // Load initial state snapshot (Safe Apply-on-Boot)
    final initialStateStr = _prefs.getString('cpu_initial_state');
    Map<String, String> initGovs = {};
    Map<String, String> initMin = {};
    Map<String, String> initMax = {};

    if (initialStateStr != null) {
      try {
        final decoded = jsonDecode(initialStateStr) as Map<String, dynamic>;
        initGovs = Map<String, String>.from(decoded['govs'] ?? {});
        initMin = Map<String, String>.from(decoded['min'] ?? {});
        initMax = Map<String, String>.from(decoded['max'] ?? {});
      } catch (_) {}
    }

    // Load dynamic settings (governors, frequencies)
    final settingsStr = _prefs.getString('cpu_settings');
    Map<String, String> currentGovernors = {};
    Map<String, String> minFreqs = {};
    Map<String, String> maxFreqs = {};

    if (settingsStr != null) {
      try {
        final decoded = jsonDecode(settingsStr) as Map<String, dynamic>;
        decoded.forEach((policy, data) {
          final map = Map<String, String>.from(data);
          currentGovernors[policy] = map['governor'] ?? '';
          minFreqs[policy] = map['min'] ?? '';
          maxFreqs[policy] = map['max'] ?? '';
        });
      } catch (_) {}
    }

    // Load selection states
    final selectionStr = _prefs.getString('cpu_selections');
    Map<String, bool> selectedGovs = {};
    Map<String, bool> selectedMin = {};
    Map<String, bool> selectedMax = {};

    if (selectionStr != null) {
      try {
        final decoded = jsonDecode(selectionStr) as Map<String, dynamic>;
        selectedGovs = Map<String, bool>.from(decoded['govs'] ?? {});
        selectedMin = Map<String, bool>.from(decoded['min'] ?? {});
        selectedMax = Map<String, bool>.from(decoded['max'] ?? {});
      } catch (_) {}
    }

    // Listen to the high-performance non-root stream
    ref.listen(cpuMonitorStreamProvider, (prev, next) {
      if (next.hasValue) {
        _syncFromSnapshot(next.value!);
      }
    });

    // Initial state with cached info
    return CpuState(
      isLoading: policies.isEmpty,
      policies: policies,
      availableGovernors: availableGovernors,
      availableFrequencies: availableFrequencies,
      currentGovernors: currentGovernors,
      minFreqs: minFreqs,
      maxFreqs: maxFreqs,
      initialGovernors: initGovs,
      initialMinFreqs: initMin,
      initialMaxFreqs: initMax,
      selectedGovernors: selectedGovs,
      selectedMinFreqs: selectedMin,
      selectedMaxFreqs: selectedMax,
      isApplyOnBootEnabled: _prefs.getBool('cpu_boot') ?? false,
    );
  }

  // --- Internal Logic
  void _syncFromSnapshot(CpuSnapshot snapshot) {
    if (state.policies.isEmpty) return;

    final newGovs = Map<String, String>.from(state.currentGovernors);
    bool changed = false;

    for (final cluster in snapshot.clusters) {
      final policy = 'policy${cluster.id}';
      if (state.policies.contains(policy)) {
        final govLabel = cluster.governor;
        if (newGovs[policy] != govLabel && govLabel != "Unknown") {
          newGovs[policy] = govLabel;
          changed = true;
        }
      }
    }

    if (changed) {
      state = state.copyWith(
        currentGovernors: newGovs,
      );
    }
  }

  // --- Actions
  Future<void> loadData({bool forceRefresh = false}) async {
    // Optimization: Skip if we already have hardware info and not forcing refresh
    if (!forceRefresh && state.policies.isNotEmpty) {
      await _refreshDynamicValues();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final policies = await _cpuShell.getCpuPolicies();
      final availableGovernors = <String, List<String>>{};
      final availableFrequencies = <String, List<String>>{};

      await Future.wait(policies.map((policy) async {
        availableGovernors[policy] =
            await _cpuShell.getAvailableGovernors(policy);
        availableFrequencies[policy] =
            await _cpuShell.getAvailableFrequencies(policy);
      }));

      // Cache static info to avoid shell calls on next launch
      final cache = {
        'policies': policies,
        'governors': availableGovernors,
        'frequencies': availableFrequencies,
      };
      await _prefs.setString('initial_cpu_info', jsonEncode(cache));

      state = state.copyWith(
        policies: policies,
        availableGovernors: availableGovernors,
        availableFrequencies: availableFrequencies,
      );

      await _refreshDynamicValues();

      // **CAPTURE INTIAL STATE IF NOT EXISTS (Safe Apply-on-Boot)**
      if (state.initialGovernors.isEmpty) {
        final initialCache = {
          'govs': state.currentGovernors,
          'min': state.minFreqs,
          'max': state.maxFreqs,
        };
        await _prefs.setString('cpu_initial_state', jsonEncode(initialCache));
        state = state.copyWith(
          initialGovernors: state.currentGovernors,
          initialMinFreqs: state.minFreqs,
          initialMaxFreqs: state.maxFreqs,
        );
      }

      // Initialize selections if empty
      if (state.selectedGovernors.isEmpty) {
        final Map<String, bool> govs = {};
        final Map<String, bool> min = {};
        final Map<String, bool> max = {};
        for (var p in policies) {
          govs[p] = true;
          min[p] = true;
          max[p] = true;
        }
        state = state.copyWith(
          selectedGovernors: govs,
          selectedMinFreqs: min,
          selectedMaxFreqs: max,
        );
        _saveSelections();
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      logger.e("CpuProvider: Error loading CPU data", e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _refreshDynamicValues() async {
    final currentGovernors = <String, String>{};
    final minFreqs = <String, String>{};
    final maxFreqs = <String, String>{};
    final currentFreqs = <String, String>{};

    await Future.wait(state.policies.map((policy) async {
      currentGovernors[policy] = await _cpuShell.getGovernor(policy);
      minFreqs[policy] = await _cpuShell.getMinFreq(policy);
      maxFreqs[policy] = await _cpuShell.getMaxFreq(policy);
      currentFreqs[policy] = await _cpuShell.getCurrentFreq(policy);
    }));

    state = state.copyWith(
      currentGovernors: currentGovernors,
      minFreqs: minFreqs,
      maxFreqs: maxFreqs,
      currentFreqs: currentFreqs,
    );
  }

  // --- Configuration Actions
  Future<void> setGovernor(String policy, String gov) async {
    logger.d("CpuProvider: Setting governor for $policy to $gov");
    try {
      await _cpuShell.setGovernor(policy, gov);

      final newGov = await _cpuShell.getGovernor(policy);
      final newMap = Map<String, String>.from(state.currentGovernors);
      newMap[policy] = newGov;
      state = state.copyWith(currentGovernors: newMap);

      await _saveSettingsAndSync();
      logger.i("Governor changed to $gov for $policy");
    } catch (e, st) {
      logger.e("Failed to set governor for $policy", e, st);
      rethrow;
    }
  }

  Future<void> setGlobalGovernor(String gov) async {
    logger.d("CpuProvider: Setting global governor to $gov");
    state = state.copyWith(isLoading: true);
    try {
      await _cpuShell.setGlobalGovernor(gov);

      final newGovs = <String, String>{};
      for (var policy in state.policies) {
        newGovs[policy] = await _cpuShell.getGovernor(policy);
      }
      state = state.copyWith(isLoading: false, currentGovernors: newGovs);

      await _saveSettingsAndSync();
      logger.i("Global governor changed to $gov for all cores");
    } catch (e, st) {
      state = state.copyWith(isLoading: false);
      logger.e("Failed to set global governor", e, st);
      rethrow;
    }
  }

  Future<void> setMinFreq(String policy, String freq) async {
    logger.d("CpuProvider: Setting min frequency for $policy to $freq");
    try {
      final currentMax = int.tryParse(state.maxFreqs[policy] ?? '0') ?? 0;
      final newMin = int.tryParse(freq) ?? 0;

      if (newMin > currentMax && currentMax > 0) {
        logger.w(
            "New min freq ($freq) is higher than current max ($currentMax). Adjusting max freq first.");
        await _cpuShell.setMaxFreq(policy, freq);
        final newMaxVal = await _cpuShell.getMaxFreq(policy);
        final newMaxMap = Map<String, String>.from(state.maxFreqs);
        newMaxMap[policy] = newMaxVal;
        state = state.copyWith(maxFreqs: newMaxMap);
      }

      await _cpuShell.setMinFreq(policy, freq);
      final newVal = await _cpuShell.getMinFreq(policy);
      final newMap = Map<String, String>.from(state.minFreqs);
      newMap[policy] = newVal;
      state = state.copyWith(minFreqs: newMap);

      await _saveSettingsAndSync();
      logger.i("Minimum frequency for $policy set to ${_formatFreq(newVal)}");
    } catch (e, st) {
      logger.e("Failed to set minimum frequency for $policy", e, st);
      rethrow;
    }
  }

  Future<void> setMaxFreq(String policy, String freq) async {
    logger.d("CpuProvider: Setting max frequency for $policy to $freq");
    try {
      final currentMin = int.tryParse(state.minFreqs[policy] ?? '0') ?? 0;
      final newMax = int.tryParse(freq) ?? 0;

      if (newMax < currentMin && currentMin > 0) {
        logger.w(
            "New max freq ($freq) is lower than current min ($currentMin). Adjusting min freq first.");
        await _cpuShell.setMinFreq(policy, freq);
        final newMinVal = await _cpuShell.getMinFreq(policy);
        final newMinMap = Map<String, String>.from(state.minFreqs);
        newMinMap[policy] = newMinVal;
        state = state.copyWith(minFreqs: newMinMap);
      }

      await _cpuShell.setMaxFreq(policy, freq);
      final newVal = await _cpuShell.getMaxFreq(policy);
      final newMap = Map<String, String>.from(state.maxFreqs);
      newMap[policy] = newVal;
      state = state.copyWith(maxFreqs: newMap);

      await _saveSettingsAndSync();
      logger.i("Maximum frequency for $policy set to ${_formatFreq(newVal)}");
    } catch (e, st) {
      logger.e("Failed to set maximum frequency for $policy", e, st);
      rethrow;
    }
  }

  Future<void> toggleApplyOnBoot(bool enabled) async {
    logger.d("CpuProvider: Toggling apply on boot to $enabled");
    try {
      await _prefs.setBool('cpu_boot', enabled);
      state = state.copyWith(isApplyOnBootEnabled: enabled);
      await _saveSettingsAndSync();

      logger.i(
          "Apply on boot ${enabled ? 'enabled' : 'disabled'} for CPU settings");
    } catch (e, st) {
      logger.e("Failed to toggle apply on boot", e, st);
      rethrow;
    }
  }

  // --- Selection Actions
  void toggleGovernorSelection(String policy) {
    final newMap = Map<String, bool>.from(state.selectedGovernors);
    newMap[policy] = !(newMap[policy] ?? true);
    state = state.copyWith(selectedGovernors: newMap);
    _saveSelections();
    _saveSettingsAndSync();
  }

  void toggleMinFreqSelection(String policy) {
    final newMap = Map<String, bool>.from(state.selectedMinFreqs);
    newMap[policy] = !(newMap[policy] ?? true);
    state = state.copyWith(selectedMinFreqs: newMap);
    _saveSelections();
    _saveSettingsAndSync();
  }

  void toggleMaxFreqSelection(String policy) {
    final newMap = Map<String, bool>.from(state.selectedMaxFreqs);
    newMap[policy] = !(newMap[policy] ?? true);
    state = state.copyWith(selectedMaxFreqs: newMap);
    _saveSelections();
    _saveSettingsAndSync();
  }

  // --- Persistence Logic
  Future<void> _saveSelections() async {
    final data = {
      'govs': state.selectedGovernors,
      'min': state.selectedMinFreqs,
      'max': state.selectedMaxFreqs,
    };
    await _prefs.setString('cpu_selections', jsonEncode(data));
  }

  Future<void> _saveSettingsAndSync() async {
    final settings = <String, Map<String, dynamic>>{};
    for (var policy in state.policies) {
      settings[policy] = {
        'governor': state.currentGovernors[policy] ?? '',
        'min': state.minFreqs[policy] ?? '',
        'max': state.maxFreqs[policy] ?? '',
        // Include selection flags for the boot script generator
        'selected_gov': state.selectedGovernors[policy] ?? true,
        'selected_min': state.selectedMinFreqs[policy] ?? true,
        'selected_max': state.selectedMaxFreqs[policy] ?? true,
      };
    }

    await _prefs.setString('cpu_settings', jsonEncode(settings));

    final info = await PackageInfo.fromPlatform();

    await _shell.syncBootSettings(
      appVersion: info.version,
      versionCode: info.buildNumber,
      cpuEnabled: state.isApplyOnBootEnabled,
      cpuDisabled: !state.isApplyOnBootEnabled,
      cpuSettings: settings,
      zramEnabled: _prefs.getBool('perf_zram_enabled') ?? false,
      zramSizeMb: _prefs.getInt('zram_size') ?? 0,
      zramAlgo: _prefs.getString('perf_zram_algo') ?? 'lzo',
      swappiness: _prefs.getInt('swappiness') ?? 60,
      vfsCachePressure: _prefs.getInt('perf_vfs_cache_pressure') ?? 100,
      layaEnabled: _prefs.getBool('laya_boot') ?? false,
      activeLayaModules: _prefs.getStringList('laya_modules') ?? [],
      thermalEnabled: _prefs.getBool('thermal_boot') ?? false,
      thermalDisabled: _prefs.getBool('thermal_disabled') ?? false,
      fpsGoEnabled: _prefs.getBool('fpsgo_boot') ?? false,
      fpsGoSettings: _getFpsGoSettings(),
    );
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

  String _formatFreq(String freq) {
    if (freq.isEmpty || freq == "Unknown") return "Unknown";
    try {
      final khz = int.parse(freq);
      if (khz >= 1000000) return "${(khz / 1000000).toStringAsFixed(1)} GHz";
      return "${khz ~/ 1000} MHz";
    } catch (e) {
      return freq;
    }
  }
}

// --- Providers Export
final cpuStateProvider = NotifierProvider<CpuNotifier, CpuState>(() {
  return CpuNotifier();
});

final cpuMonitorStreamProvider = StreamProvider<CpuSnapshot>((ref) {
  cpuMonitor.init(ref.read(shellServiceProvider));
  cpuMonitor.start();

  ref.onDispose(() {
    cpuMonitor.stop();
  });

  return cpuMonitor.stats;
});
