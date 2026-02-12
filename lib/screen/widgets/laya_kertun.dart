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
// Dedicated Widget for Laya Kernel Tuner Card
// --- LayaKernelTunerCard
class LayaKernelTunerCard extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback onLog;
  final Function(bool) onBootChanged;

  const LayaKernelTunerCard({
    super.key,
    required this.onTap,
    required this.onAction,
    required this.onLog,
    required this.onBootChanged,
  });

  // --- Configuration
  static const config = AddonConfig(
    id: "laya-kernel-tuner",
    name: "Laya Kernel Tuner",
    description:
        "Smart kernel optimizer that auto-tunes your device for battery life without breaking performance.",
    longDescription:
        "This runs 4 profiles automatically: super battery saver when screen's off, balanced mode during normal use, max performance when you need it, and gaming mode for demanding apps. It watches what you're doing and adjusts kernel parameters on the fly—no user babysitting needed. Works silently in the background, barely uses any CPU, and can give you 10-20% better battery just sitting idle. Built for 64-bit Android 11+ with Kernel 4.14+.",
    version: "6.0-STABLE",
    author: "Laya",
    license: "GPL-3.0",
    licensePath: "assets/license/LICENSE-LayaKernelTuner",
    icon: LucideIcons.cpu,
    features: [
      "Dynamic CPU Scaling",
      "Kernel Parameter Optimization",
      "Process Priority Management",
      "Thermal Governor Tuning"
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // State Management
    final moduleState = ref.watch(moduleStateProvider);

    final isRunning = moduleState.isKernelTunerRunning;
    final hasModule = moduleState.hasKernelTunerModule;
    final isBootEnabled = moduleState.isKTBootEnabled;
    final pid = moduleState.ktPid;
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
