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
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../../providers/shared_prefs_provider.dart';
import '../../services/shell_services.dart';
import '../../shell/shell_zram.dart';
import '../../shell/shell_swappiness.dart';
import '../statusbar/sb_memorymanager.dart';
import '../../utils/app_logger.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import '../widgets/zram_allocation.dart';
import '../widgets/advanced_tuning.dart';
import '../../animations/splashscreen_animation.dart';

// ---- MAJOR ---
// Primary Page for Managing ZRAM and Kernel Memory Parameters
class MemoryManagerPage extends ConsumerStatefulWidget {
  const MemoryManagerPage({super.key});

  @override
  ConsumerState<MemoryManagerPage> createState() => _MemoryManagerPageState();
}

class _MemoryManagerPageState extends ConsumerState<MemoryManagerPage> {
  // ---- STATE VARIABLES ---
  bool _isLoading = true;
  double _currentZramSize = 0;
  double _sliderValue = 0;
  double _swappinessSliderValue = 60;
  bool _applyOnBoot = false;
  bool _isUnlocked = false;

  // --- Kernel Limits
  int _totalRamMB = 0;
  int _safeLimitMB = 0; // 2x RAM
  int _hardLimitMB = 0; // 3x RAM (Max Cap)

  // --- Baseline State
  double? _initialZramSize;
  double? _initialSwappiness;
  String? _initialAlgo;
  double? _initialVfsPressure;

  // --- Advanced Tuning
  List<String> _availableAlgos = [];
  String _selectedAlgo = 'lzo';
  double _vfsPressure = 100;

  // --- Controllers
  final TextEditingController _controller = TextEditingController();

  // ---- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadZramData();
  }

  // ---- DATA ENGINE ---

  Future<void> _loadZramData() async {
    try {
      final zramShell = ref.read(zramShellProvider);
      final swappinessShell = ref.read(swappinessShellProvider);
      final prefs = ref.read(sharedPreferencesProvider);

      final zramSize = await zramShell.getZramSize();
      final totalRam = await zramShell.getTotalRam();
      final algos = await zramShell.getAvailableAlgorithms();
      final curAlgo = await zramShell.getActiveAlgorithm();
      final pressure = await swappinessShell.getVfsCachePressure();

      if (mounted) {
        setState(() {
          _totalRamMB = totalRam > 0 ? totalRam : 4096;
          _safeLimitMB = (_totalRamMB * 2);
          _hardLimitMB = (_totalRamMB * 3);

          _currentZramSize = zramSize.toDouble();
          _applyOnBoot = prefs.getBool('perf_zram_enabled') ?? false;

          _sliderValue = _currentZramSize;

          if (_sliderValue > _safeLimitMB) {
            _isUnlocked = true;
          }

          _controller.text = _sliderValue.toInt().toString();

          final savedSwappiness = prefs.getInt('swappiness');
          _swappinessSliderValue = (savedSwappiness ?? 60).toDouble();

          _availableAlgos = algos;
          final savedAlgo = prefs.getString('perf_zram_algo');
          _selectedAlgo = savedAlgo ?? curAlgo;

          final savedPressure = prefs.getInt('perf_vfs_cache_pressure');
          _vfsPressure = savedPressure?.toDouble() ?? pressure.toDouble();

          _initialZramSize = _currentZramSize;
          _initialSwappiness = (savedSwappiness ?? 60).toDouble();
          _initialAlgo = curAlgo;
          _initialVfsPressure = pressure.toDouble();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---- LOGIC HANDLERS ---

  void _onSliderChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() {
      _sliderValue = value;
      _controller.text = value.toInt().toString();
    });
  }

  void _onTextChanged(String value) {
    final int? parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    final double maxAllowed =
        _isUnlocked ? _hardLimitMB.toDouble() : _safeLimitMB.toDouble();

    if (parsed > maxAllowed) {
      _controller.text = maxAllowed.toInt().toString();
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
      setState(() => _sliderValue = maxAllowed);
      HapticFeedback.heavyImpact();
    } else {
      setState(() => _sliderValue = parsed.toDouble());
    }
  }

  // ---- KERNEL INTERACTIONS ---

  Future<void> _applySettings() async {
    HapticFeedback.mediumImpact();

    final targetMB = _sliderValue.toInt();
    final targetSwappiness = _swappinessSliderValue.toInt();
    final targetVfsPressure = _vfsPressure.toInt();

    final zramShell = ref.read(zramShellProvider);
    final swappinessShell = ref.read(swappinessShellProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    final dismissLoading =
        RootifyToast.showLoading(context, "Applying memory parameters...");

    try {
      final algoChanged = _selectedAlgo != _initialAlgo;
      final sizeChanged = targetMB != _initialZramSize?.toInt();
      final swappinessChanged = targetSwappiness != _initialSwappiness?.toInt();
      final vfsChanged = targetVfsPressure != _initialVfsPressure?.toInt();

      if (algoChanged || sizeChanged) {
        await zramShell.applyParameters(
          sizeMB: targetMB,
          algo: _selectedAlgo,
        );
      }

      if (swappinessChanged) {
        await swappinessShell.setSwappiness(targetSwappiness);
      }

      if (vfsChanged) {
        await swappinessShell.setVfsCachePressure(targetVfsPressure);
      }

      await prefs.setInt('zram_size', targetMB);
      await prefs.setInt('swappiness', targetSwappiness);
      await prefs.setString('perf_zram_algo', _selectedAlgo);
      await prefs.setInt('perf_vfs_cache_pressure', targetVfsPressure);

      await _syncBoot();

      final finalSize = await zramShell.getZramSize();
      if (mounted) {
        setState(() {
          _currentZramSize = finalSize.toDouble();
          _sliderValue = finalSize.toDouble();
          _initialZramSize = finalSize.toDouble();
          _initialSwappiness = targetSwappiness.toDouble();
          _initialAlgo = _selectedAlgo;
          _initialVfsPressure = targetVfsPressure.toDouble();
        });

        dismissLoading();
        RootifyToast.success(context, "Memory optimization applied");
      }
    } catch (e, st) {
      dismissLoading();
      logger.e("Memory Manager error", e, st);
      if (mounted) {
        RootifyToast.error(context, "Failed to apply settings: $e");
      }
    }
  }

  Future<void> _syncBoot() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = ref.read(sharedPreferencesProvider);

    final cpuSettingsStr = prefs.getString('cpu_settings');
    Map<String, dynamic> cpuSettings = {};
    if (cpuSettingsStr != null) {
      try {
        final decoded = jsonDecode(cpuSettingsStr) as Map<String, dynamic>;
        cpuSettings = decoded.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      } catch (_) {}
    }

    final fpsgoSettingsStr = prefs.getString('fpsgo_settings');
    Map<String, dynamic> fpsgoSettings = {};
    if (fpsgoSettingsStr != null) {
      try {
        fpsgoSettings = Map<String, dynamic>.from(jsonDecode(fpsgoSettingsStr));
      } catch (_) {}
    }

    await ref.read(shellServiceProvider).syncBootSettings(
          appVersion: info.version,
          versionCode: info.buildNumber,
          cpuEnabled: prefs.getBool('cpu_boot') ?? false,
          cpuDisabled: !(prefs.getBool('cpu_boot') ?? false),
          cpuSettings: cpuSettings,
          zramEnabled: prefs.getBool('perf_zram_enabled') ?? true,
          zramSizeMb: prefs.getInt('zram_size') ?? 0,
          zramAlgo: prefs.getString('perf_zram_algo') ?? 'lzo',
          swappiness: prefs.getInt('swappiness') ?? 60,
          vfsCachePressure: prefs.getInt('perf_vfs_cache_pressure') ?? 100,
          layaEnabled: prefs.getBool('laya_boot') ?? false,
          activeLayaModules: prefs.getStringList('laya_modules') ?? [],
          thermalEnabled: prefs.getBool('thermal_boot') ?? false,
          thermalDisabled: prefs.getBool('thermal_disabled') ?? false,
          fpsGoEnabled: prefs.getBool('fpsgo_boot') ?? false,
          fpsGoSettings: fpsgoSettings,
        );
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // --- Sub
            // 1. Mirrored Dynamic Mesh Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Detail: Primary Glow
                    Positioned(
                      top: -120,
                      left: -120,
                      child: Container(
                        width: 450,
                        height: 450,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.15),
                              colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(30, -30),
                          end: const Offset(-30, 30),
                          duration: 12.seconds),
                    ),
                    // Detail: Secondary Glow
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.secondary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(-30, 30),
                          end: const Offset(30, -30),
                          duration: 10.seconds),
                    ),
                  ],
                ),
              ),
            ),

            // --- Sub
            // 2. Content Logic Layer
            _isLoading
                ? Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: SplashScreenAnimation.drawPathAnimation(
                        path: SplashScreenAnimation.getOfficialLogoPath(
                            const Size(60, 60)),
                        color: colorScheme.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    ),
                  )
                : CustomScrollView(
                    key: const PageStorageKey('memory_manager_page_scroll'),
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Detail: Header Space
                      SliverToBoxAdapter(
                          child: SizedBox(height: topPadding + 80)),

                      // Detail: Header Branding & Boot Persistence
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ZRAM",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            height: 1.0,
                                            color: theme.colorScheme.primary)),
                                    Text("TWEAKING",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2.0,
                                            height: 1.0,
                                            color: theme.colorScheme.primary)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 215,
                                child: _buildApplyOnBootToggle(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Detail: Allocation Control Interface
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: ZramAllocationCard(
                            totalRamMB: _totalRamMB,
                            sliderValue: _sliderValue,
                            safeLimitMB: _safeLimitMB.toDouble(),
                            hardLimitMB: _hardLimitMB.toDouble(),
                            isUnlocked: _isUnlocked,
                            controller: _controller,
                            onSliderChanged: _onSliderChanged,
                            onTextChanged: _onTextChanged,
                            onUnlock: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _isUnlocked = true);
                              RootifyToast.show(
                                  context, "Limit unlocked! Be careful.",
                                  icon: LucideIcons.alertTriangle);
                            },
                          ),
                        ),
                      ),

                      // Detail: Advanced Property Tuning
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: AdvancedTuningCard(
                            availableAlgos: _availableAlgos,
                            selectedAlgo: _selectedAlgo,
                            swappinessValue: _swappinessSliderValue,
                            vfsPressureValue: _vfsPressure,
                            onAlgoSelected: (algo) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAlgo = algo);
                            },
                            onSwappinessChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _swappinessSliderValue = val);
                            },
                            onVfsPressureChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _vfsPressure = val);
                            },
                          ),
                        ),
                      ),

                      // Detail: Operational Execution Control
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: _buildApplyButton(context),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),

            // --- Sub
            // 3. Floating Feature Status Bar
            Positioned(
              top: topPadding + 10,
              left: 0,
              right: 0,
              child: const MemoryStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- COMPONENT BUILDERS ----

  Widget _buildApplyOnBootToggle(BuildContext context) {
    final theme = Theme.of(context);
    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.power,
                size: 14,
                color:
                    _applyOnBoot ? theme.colorScheme.primary : theme.hintColor,
              ),
              const SizedBox(width: 10),
              const Text(
                "Apply on Boot",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _applyOnBoot,
              onChanged: (val) async {
                HapticFeedback.lightImpact();

                final prefs = ref.read(sharedPreferencesProvider);
                final isModified = (_currentZramSize != _sliderValue ||
                    (prefs.getInt('swappiness') ?? 60).toDouble() !=
                        _swappinessSliderValue ||
                    (prefs.getString('perf_zram_algo') ?? 'lzo') !=
                        _selectedAlgo ||
                    (prefs.getInt('perf_vfs_cache_pressure') ?? 100) !=
                        _vfsPressure.toInt());

                if (val && !isModified) {
                  RootifyToast.show(context,
                      "Configure settings before enabling Apply on Boot.",
                      isError: true);
                  return;
                }

                final dismiss =
                    RootifyToast.showLoading(context, "Synchronizing...");

                try {
                  final prefs = ref.read(sharedPreferencesProvider);
                  await prefs.setBool('perf_zram_enabled', val);

                  if (val) {
                    final currentSaved = prefs.getInt('zram_size') ?? 0;
                    if (currentSaved == 0) {
                      await prefs.setInt('zram_size', _sliderValue.toInt());
                    }
                  }

                  setState(() => _applyOnBoot = val);
                  await _syncBoot();

                  dismiss();
                  if (context.mounted) {
                    RootifyToast.success(context,
                        "Apply on Boot ${val ? 'enabled' : 'disabled'} for Memory");
                  }
                } catch (e) {
                  dismiss();
                  if (context.mounted) {
                    RootifyToast.error(context, "Failed: $e");
                  }
                }
              },
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              activeThumbColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.read(sharedPreferencesProvider);
    final isModified = (_currentZramSize != _sliderValue ||
        (prefs.getInt('swappiness') ?? 60).toDouble() !=
            _swappinessSliderValue ||
        (prefs.getString('perf_zram_algo') ?? 'lzo') != _selectedAlgo ||
        (prefs.getInt('perf_vfs_cache_pressure') ?? 100) !=
            _vfsPressure.toInt());

    final borderRadius = BorderRadius.circular(28);

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: isModified ? _applySettings : null,
        icon: const Icon(LucideIcons.zap, size: 18),
        label: Text(
          isModified ? "APPLY SETTINGS" : "SETTINGS APPLIED",
          style: const TextStyle(
              fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(
            color: isModified
                ? theme.colorScheme.primary
                : theme.disabledColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
