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
import '../../services/ramzram.dart';
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Memory (RAM & ZRAM) Information Section with Realtime Gauges
// --- MemorySection
class MemorySection extends ConsumerWidget {
  const MemorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);

    return RootifyCard(
      title: "Memory",
      icon: LucideIcons.database,
      child: _MemoryRealtimeInfo(theme: theme, ref: ref),
    );
  }
}

// Supporting widget for Memory realtime monitoring
// --- MemoryRealtimeInfo
class _MemoryRealtimeInfo extends StatelessWidget {
  final ThemeData theme;
  final WidgetRef ref;

  const _MemoryRealtimeInfo({
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // RAM Stream
    final snapshotAsync = ref.watch(ramStreamProvider);

    return snapshotAsync.when(
      data: (snapshot) {
        return Column(
          children: [
            _MemoryGauge(
              title: 'RAM',
              totalMb: snapshot.ram.totalMb.toDouble(),
              usedMb: snapshot.ram.usedMb.toDouble(),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _MemoryGauge(
              title: 'ZRAM',
              totalMb: snapshot.zram.totalMb.toDouble(),
              usedMb: snapshot.zram.usedMb.toDouble(),
              theme: theme,
              isZram: true,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Visual Gauge for Memory usage
// --- MemoryGauge
class _MemoryGauge extends StatelessWidget {
  final String title;
  final double totalMb;
  final double usedMb;
  final ThemeData theme;
  final bool isZram;

  const _MemoryGauge({
    required this.title,
    required this.totalMb,
    required this.usedMb,
    required this.theme,
    this.isZram = false,
  });

  @override
  Widget build(BuildContext context) {
    // --- Stats
    final safeTotal = totalMb <= 0 ? 1.0 : totalMb;
    final progress = (usedMb / safeTotal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(0);

    final totalGb = (totalMb / 1024).toStringAsFixed(1);
    final usedGb = (usedMb / 1024).toStringAsFixed(1);

    // --- Detail
    // Dynamic Color Mapping
    Color progressColor = theme.primaryColor;
    if (progress > 0.85) {
      progressColor = Colors.redAccent;
    } else if (progress > 0.6) {
      progressColor = Colors.orangeAccent;
    }

    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isZram ? LucideIcons.hardDrive : LucideIcons.memoryStick,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(title.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: theme.colorScheme.onSurface,
                      )),
                ],
              ),
              Text("$percentage%",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: progressColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Used: ${usedGb}GB", style: theme.textTheme.bodySmall),
              Text("Total: ${totalGb}GB", style: theme.textTheme.bodySmall),
            ],
          )
        ],
      ),
    );
  }
}
