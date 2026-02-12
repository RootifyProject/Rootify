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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../providers/addons_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import '../../shell/shell_layakertun.dart';
import '../../shell/shell_layabattmon.dart';
import '../../utils/app_logger.dart';
import '../pages-sub/addon_detail.dart';
import '../overlays/log.dart';
import '../widgets/laya_kertun.dart';
import '../widgets/laya_battmon.dart';

// ---- MAJOR ---
// Static Metadata for Supported Addon Services
class AddonConfig {
  final String id;
  final String name;
  final String description;
  final String longDescription;
  final String version;
  final String author;
  final String license;
  final String licensePath;
  final IconData icon;
  final List<String> features;

  const AddonConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.longDescription,
    required this.version,
    required this.author,
    required this.license,
    required this.licensePath,
    required this.icon,
    required this.features,
  });
}

const AddonConfig layaKertunConfig = LayaKernelTunerCard.config;
const AddonConfig layaBattmonConfig = LayaBatteryMonitorCard.config;

// ---- MAJOR ---
// Primary Interface for External Service Management
class AddonsPage extends ConsumerStatefulWidget {
  const AddonsPage({super.key});

  @override
  ConsumerState<AddonsPage> createState() => AddonsPageState();
}

class AddonsPageState extends ConsumerState<AddonsPage> {
  // --- Lifecycle
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moduleStateProvider.notifier).loadStatus();
    });
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Component Assembly
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        key: const PageStorageKey('addons_page_scroll'),
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 80, 16, 120),
        child: Column(
          children: [
            LayaKernelTunerCard(
              onTap: () => _navigateToDetail(context, layaKertunConfig),
              onAction: () => _handleAction(layaKertunConfig.id),
              onLog: () => _showLog(layaKertunConfig.id),
              onBootChanged: (val) => _handleBootChange(layaKertunConfig, val),
            ),
            LayaBatteryMonitorCard(
              onTap: () => _navigateToDetail(context, layaBattmonConfig),
              onAction: () => _handleAction(layaBattmonConfig.id),
              onLog: () => _showLog(layaBattmonConfig.id),
              onBootChanged: (val) => _handleBootChange(layaBattmonConfig, val),
            ),
          ],
        ),
      ),
    );
  }

  // ---- LOGIC HANDLERS ---

  void _navigateToDetail(BuildContext context, AddonConfig config) {
    final moduleState = ref.read(moduleStateProvider);
    final isRunning = config.id == "laya-kernel-tuner"
        ? moduleState.isKernelTunerRunning
        : moduleState.isBatteryMonitorRunning;
    final hasModule = config.id == "laya-kernel-tuner"
        ? moduleState.hasKernelTunerModule
        : moduleState.hasBatteryMonitorModule;
    final pid = config.id == "laya-kernel-tuner"
        ? moduleState.ktPid
        : moduleState.bmPid;
    final isProcessing = moduleState.processingAddons[config.id] ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddonDetailPage(
          config: config,
          isRunning: isRunning,
          pid: pid,
          isProcessing: isProcessing,
          isModuleMode: hasModule && isRunning,
          onAction: () => _handleAction(config.id),
          onLog: () => _showLog(config.id),
        ),
      ),
    ).then((_) => ref.read(moduleStateProvider.notifier).refresh());
  }

  void _handleAction(String addonId) {
    final isRunning = addonId == "laya-kernel-tuner"
        ? ref.read(moduleStateProvider).isKernelTunerRunning
        : ref.read(moduleStateProvider).isBatteryMonitorRunning;

    if (isRunning) {
      _stopBinary(addonId);
    } else {
      _installAndRun(addonId);
    }
  }

  Future<void> _handleBootChange(AddonConfig config, bool val) async {
    try {
      if (config.id == "laya-kernel-tuner") {
        await ref.read(moduleStateProvider.notifier).toggleKTBoot(val);
      } else {
        await ref.read(moduleStateProvider.notifier).toggleBMBoot(val);
      }
      if (mounted) {
        RootifyToast.success(context,
            "Apply on Boot ${val ? 'enabled' : 'disabled'} for ${config.name}");
      }
    } catch (e) {
      if (mounted) {
        RootifyToast.error(
            context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // --- Sub
  // Service Initialization Flow
  Future<void> _installAndRun(String binaryName) async {
    logger.i("AddonsPage: Initializing service -> $binaryName");
    ref.read(moduleStateProvider.notifier).setProcessing(binaryName, true);

    final dismiss = RootifyToast.showLoading(context,
        "Starting ${binaryName.replaceAll('laya-', '').toUpperCase()}...");

    try {
      final binDir = Directory("/data/data/com.aby.rootify/files/bin");
      if (!await binDir.exists()) await binDir.create(recursive: true);

      final file = File("${binDir.path}/$binaryName");
      if (!await file.exists()) {
        final data = await rootBundle.load("assets/bin/$binaryName");
        await file.writeAsBytes(data.buffer.asUint8List());
      }

      if (binaryName == "laya-kernel-tuner") {
        await ref.read(layakertunShellProvider).startKernelTuner();
      } else {
        await ref.read(layabattmonShellProvider).startBatteryMonitor();
      }

      await ref
          .read(moduleStateProvider.notifier)
          .refresh(retries: 5, checkAddonId: binaryName, expectRunning: true);
      dismiss();
      if (mounted) {
        RootifyToast.success(context,
            "${binaryName.replaceAll('laya-', '').toUpperCase()} started");
      }
    } catch (e) {
      dismiss();
      if (mounted) RootifyToast.error(context, "Start failed: $e");
    } finally {
      ref.read(moduleStateProvider.notifier).setProcessing(binaryName, false);
    }
  }

  // --- Sub
  // Service Cessation Flow
  Future<void> _stopBinary(String binaryName) async {
    logger.w("AddonsPage: Stopping service -> $binaryName");
    ref.read(moduleStateProvider.notifier).setProcessing(binaryName, true);

    final dismiss = RootifyToast.showLoading(context,
        "Stopping ${binaryName.replaceAll('laya-', '').toUpperCase()}...");

    try {
      if (binaryName == "laya-kernel-tuner") {
        await ref.read(layakertunShellProvider).stopKernelTuner();
      } else {
        await ref.read(layabattmonShellProvider).stopBatteryMonitor();
      }
      await Future.delayed(const Duration(seconds: 1));
      await ref
          .read(moduleStateProvider.notifier)
          .refresh(retries: 5, checkAddonId: binaryName, expectRunning: false);

      dismiss();
      if (mounted) {
        RootifyToast.success(context,
            "${binaryName.replaceAll('laya-', '').toUpperCase()} stopped");
      }
    } catch (e) {
      dismiss();
      if (mounted) RootifyToast.error(context, "Stop failed: $e");
    } finally {
      ref.read(moduleStateProvider.notifier).setProcessing(binaryName, false);
    }
  }

  // --- Sub
  // Logs Contextualizer
  Future<void> _showLog(String binaryName) async {
    final title = binaryName.replaceAll('-', ' ').toUpperCase();
    String logs = "Loading logs...";

    if (binaryName == "laya-kernel-tuner") {
      logs = await ref.read(layakertunShellProvider).getKTLogs();
    } else {
      logs = await ref.read(layabattmonShellProvider).getBMLogs();
    }

    if (!mounted) return;

    LogOverlay.show(
      context,
      title,
      logs,
      onRefresh: () async {
        return binaryName == "laya-kernel-tuner"
            ? await ref.read(layakertunShellProvider).getKTLogs()
            : await ref.read(layabattmonShellProvider).getBMLogs();
      },
      onClear: () async {
        binaryName == "laya-kernel-tuner"
            ? await ref.read(layakertunShellProvider).clearKTLogs()
            : await ref.read(layabattmonShellProvider).clearBMLogs();
      },
    );
  }
}

// ---- MAJOR ---
// Visual Card for Addon Status & Controls
class AddonCard extends StatelessWidget {
  final AddonConfig config;
  final bool isRunning;
  final int? pid;
  final bool isProcessing;
  final bool isModuleMode;
  final bool isBootEnabled;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback onLog;
  final Function(bool) onBootChanged;

  const AddonCard({
    super.key,
    required this.config,
    required this.isRunning,
    this.pid,
    required this.isProcessing,
    required this.isModuleMode,
    required this.isBootEnabled,
    required this.onTap,
    required this.onAction,
    required this.onLog,
    required this.onBootChanged,
  });

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- Component Assembly
    return RootifyCard(
      title: config.name,
      subtitle: isRunning
          ? "ACTIVE • PID: ${pid ?? '...'}"
          : "INACTIVE • v${config.version.split('-')[0]}",
      icon: config.icon,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail: Description Context
          Text(config.description,
              style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  height: 1.5)),
          const SizedBox(height: 16),

          // --- Sub
          // Startup Persistence Toggle
          RootifySubCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.power,
                        size: 14,
                        color: isBootEnabled
                            ? theme.colorScheme.primary
                            : theme.hintColor),
                    const SizedBox(width: 12),
                    const Text("APPLY ON BOOT",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1)),
                  ],
                ),
                Transform.scale(
                    scale: 0.75,
                    child: Switch(
                        value: isBootEnabled,
                        onChanged: onBootChanged,
                        activeTrackColor:
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: theme.colorScheme.primary,
                        inactiveTrackColor:
                            theme.colorScheme.outline.withValues(alpha: 0.2),
                        inactiveThumbColor: theme.colorScheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Sub
          // Primary Action Row
          Row(
            children: [
              if (isRunning && !isProcessing)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: onLog,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Icon(LucideIcons.fileText,
                          size: 18, color: theme.hintColor),
                    ),
                  ),
                ),
              if (!isModuleMode)
                Expanded(
                  flex: 2,
                  child: AddonActionButton(
                    label: isRunning ? "STOP SERVICE" : "RUN SERVICE",
                    onPressed: isProcessing ? null : onAction,
                    isRunning: isRunning,
                    theme: theme,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Custom Styled Button for Binary State Changes
class AddonActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isRunning;
  final ThemeData theme;

  const AddonActionButton({
    super.key,
    required this.label,
    this.onPressed,
    required this.isRunning,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final isEnabled = onPressed != null;
    final color1 =
        isRunning ? const Color(0xFFEF4444) : theme.colorScheme.primary;
    final color2 = isRunning
        ? const Color(0xFFB91C1C)
        : theme.colorScheme.primary.withValues(alpha: 0.8);

    // --- Component Assembly
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isEnabled
            ? LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: isEnabled ? null : theme.disabledColor.withValues(alpha: 0.1),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                    color: color1.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28))),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }
}
