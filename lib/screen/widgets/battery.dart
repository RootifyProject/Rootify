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
import '../../services/battery.dart';
import '../../widgets/cards.dart';
import 'info_widgets.dart';

// ---- MAJOR ---
// Battery Information Section with Realtime Monitoring
// --- BatterySection
class BatterySection extends ConsumerWidget {
  const BatterySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);

    return RootifyCard(
      title: "Battery",
      icon: LucideIcons.battery,
      child: _BatteryRealtimeInfo(theme: theme, ref: ref),
    );
  }
}

// Supporting widget for Battery realtime monitoring
// --- BatteryRealtimeInfo
class _BatteryRealtimeInfo extends StatelessWidget {
  final ThemeData theme;
  final WidgetRef ref;

  const _BatteryRealtimeInfo({
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Battery Stream
    final snapshotAsync = ref.watch(batteryStreamProvider);

    return snapshotAsync.when(
      data: (snapshot) {
        return Column(
          children: [
            InfoDetailTile(
              icon: LucideIcons.thermometer,
              label: "Temperature",
              value: "${snapshot.temp.celsius.toStringAsFixed(1)}°C",
            ),
            InfoDetailTile(
              icon: LucideIcons.zap,
              label: "Current Draw",
              value: "${snapshot.current.now} mA",
            ),
            InfoDetailTile(
              icon: LucideIcons.heartPulse,
              label: "Battery Health",
              value: snapshot.health.status,
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
