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
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../providers/addons_provider.dart';
import '../pages/addons.dart';

// ---- MAJOR ---
// Dedicated Widget for Laya Battery Monitor Card
// --- LayaBatteryMonitorCard
class LayaBatteryMonitorCard extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback onLog;
  final Function(bool) onBootChanged;

  const LayaBatteryMonitorCard({
    super.key,
    required this.onTap,
    required this.onAction,
    required this.onLog,
    required this.onBootChanged,
  });

  // --- Configuration
  static const config = AddonConfig(
    id: "laya-battery-monitor",
    name: "Laya Battery Monitor",
    description:
        "Lightweight daemon that throttles CPU when screen's off to save battery.",
    longDescription:
        "Written in Rust for speed and efficiency. When your screen turns off, it automatically pulls back CPU power and switches to power-saver mode. Instead of constantly polling (which drains battery), it uses smart event hooks to react instantly. Keeps temps chill, especially when you're hotspotting. Basically invisible—no UI, no notifications, just works. Compatible everywhere.",
    version: "4.5-STABLE",
    author: "Laya",
    license: "MIT",
    licensePath: "assets/license/LICENSE-LayaBatteryMonitor",
    icon: LucideIcons.battery,
    features: [
      "Smart CPU Policy Handling",
      "Event-Driven Power Saving",
      "Microsecond-Class Efficiency",
      "No System Bloat"
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // State Management
    final moduleState = ref.watch(moduleStateProvider);

    final isRunning = moduleState.isBatteryMonitorRunning;
    final hasModule = moduleState.hasBatteryMonitorModule;
    final isBootEnabled = moduleState.isBMBootEnabled;
    final pid = moduleState.bmPid;
    final isProcessing = moduleState.processingAddons[config.id] ?? false;

    // --- Sub
    // Card Rendering
    return AddonCard(
      config: config,
      isRunning: isRunning,
      pid: pid,
      isProcessing: isProcessing,
      isModuleMode: hasModule && isRunning,
      isBootEnabled: isBootEnabled,
      onTap: onTap,
      onAction: onAction,
      onLog: onLog,
      onBootChanged: onBootChanged,
    );
  }
}
