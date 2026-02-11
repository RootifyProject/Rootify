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
import '../../services/cpu.dart';
import '../../providers/cpu_provider.dart';
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Real-time Visualizer for CPU Core Utilization
class CpuMonitor extends ConsumerWidget {
  const CpuMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Data Streams
    final cpuSnapshotAsync = ref.watch(cpuMonitorStreamProvider);
    final cpuState = ref.watch(cpuStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detail: Lifecycle Data Warmup
    if (cpuState.policies.isEmpty && !cpuState.isLoading) {
      Future.microtask(() => ref.read(cpuStateProvider.notifier).loadData());
    }

    // --- Hardware Calculations
    double hardwareMax = 0;
    for (final frequencies in cpuState.availableFrequencies.values) {
      for (final f in frequencies) {
        final val = double.tryParse(f) ?? 0;
        if (val > hardwareMax) hardwareMax = val;
      }
    }

    // --- Logical Rendering
    return cpuSnapshotAsync.when(
      data: (snapshot) {
        if (snapshot.cores.isEmpty) return const SizedBox.shrink();

        final maxInSnapshot =
            snapshot.cores.fold(0, (p, c) => c.freq > p ? c.freq : p);
        final visualMax =
            hardwareMax > 0 ? hardwareMax : maxInSnapshot.toDouble();
        final int crossAxisCount =
            (snapshot.cores.length / 2).ceil().clamp(2, 4);

        return RootifyCard(
          title: "CPU MONITOR",
          subtitle: "REAL-TIME CPU MONITORING",
          icon: LucideIcons.cpu,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sub
              // Vitality Summary Header
              _buildHeader(colorScheme, snapshot),
              const SizedBox(height: 24),

              // --- Sub
              // Symmetrical Core Activity Grid
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRow(context, snapshot, 0, crossAxisCount, visualMax),
                  const SizedBox(height: 12),
                  _buildRow(context, snapshot, crossAxisCount, crossAxisCount,
                      visualMax),
                ],
              ),

              const SizedBox(height: 28),

              // --- Sub
              // Normalized Global Utilization
              _buildGlobalLoad(colorScheme, snapshot, visualMax),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ---- INTERNAL HELPERS ---

  // --- Sub
  // Recursive Core Row Generator
  Widget _buildRow(BuildContext context, CpuSnapshot snapshot, int startIndex,
      int count, double visualMax) {
    final totalCores = snapshot.cores.length;
    List<Widget> children = [];

    for (int i = 0; i < count; i++) {
      final index = startIndex + i;
      if (index < totalCores) {
        children.add(Expanded(
            child: _buildCoreItem(
                context, index, snapshot.cores[index], visualMax)));
      } else {
        children.add(const Expanded(child: SizedBox.shrink()));
      }
      if (i < count - 1) children.add(const SizedBox(width: 12));
    }
    return Row(mainAxisSize: MainAxisSize.max, children: children);
  }

  // --- Sub
  // Monitor Activity Headers
  Widget _buildHeader(ColorScheme colorScheme, CpuSnapshot snapshot) {
    final activeCores = snapshot.cores.where((c) => c.isOnline).length;
    final temp = snapshot.packageTemp != 0
        ? "${snapshot.packageTemp.toStringAsFixed(1)}°C"
        : "N/A";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text("$activeCores CORES ONLINE",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  letterSpacing: 0.5)),
        ),
        if (snapshot.packageTemp != 0)
          Row(
            children: [
              Icon(LucideIcons.thermometer, size: 16, color: colorScheme.error),
              const SizedBox(width: 4),
              Text(temp,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
      ],
    );
  }

  // --- Sub
  // Core-Specific Utilization Pillar
  Widget _buildCoreItem(
      BuildContext context, int index, CpuCore core, double visualMax) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOffline = !core.isOnline;
    final freqMhz = core.freq ~/ 1000;
    final usageFactor =
        isOffline ? 0.0 : (core.freq / visualMax).clamp(0.0, 1.0);

    Color barColor = isOffline ? colorScheme.outline : colorScheme.primary;
    if (!isOffline) {
      if (usageFactor > 0.8) {
        barColor = colorScheme.error;
      } else if (usageFactor > 0.5) {
        barColor = colorScheme.tertiary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            width: 5,
            decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.5)),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 5,
                  height: 36 * usageFactor,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2.5),
                    boxShadow: [
                      if (!isOffline)
                        BoxShadow(
                            color: barColor.withValues(alpha: 0.3),
                            blurRadius: 6)
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(isOffline ? "OFF" : "$freqMhz",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Monospace',
                      color: isOffline
                          ? colorScheme.outline
                          : colorScheme.onSurface))),
          Text("CORE ${index + 1}",
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  // --- Sub
  // Aggregated System Pressure Metrics
  Widget _buildGlobalLoad(
      ColorScheme colorScheme, CpuSnapshot snapshot, double visualMax) {
    final avgLoad = snapshot.totalLoad / 100.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("AVERAGE CPU LOAD",
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0)),
            Text("${snapshot.totalLoad.toStringAsFixed(0)}%",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 5,
          decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.5)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: avgLoad.clamp(0.01, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2.5),
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
