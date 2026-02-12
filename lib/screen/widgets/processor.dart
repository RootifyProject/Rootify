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
import '../../providers/cpu_provider.dart';
import '../../widgets/cards.dart';
import 'info_widgets.dart';

// ---- MAJOR ---
// Processor Information Section with Realtime Monitoring
// --- ProcessorSection
class ProcessorSection extends ConsumerWidget {
  const ProcessorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);

    return RootifyCard(
      title: "Processor",
      icon: LucideIcons.cpu,
      child: _ProcessorRealtimeInfo(theme: theme, ref: ref),
    );
  }
}

// Supporting widget for CPU realtime monitoring
// --- ProcessorRealtimeInfo
class _ProcessorRealtimeInfo extends StatelessWidget {
  final ThemeData theme;
  final WidgetRef ref;

  const _ProcessorRealtimeInfo({
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // CPU Stream
    final snapshotAsync = ref.watch(cpuMonitorStreamProvider);

    return snapshotAsync.when(
      data: (snapshot) {
        final clusters = snapshot.clusters.length;
        final cores = snapshot.cores.length;
        final govs =
            snapshot.clusters.map((c) => c.governor).toSet().join(" / ");

        return Column(
          children: [
            InfoDetailTile(
              icon: LucideIcons.layers,
              label: "Topology",
              value: "$clusters Clusters / $cores Cores",
            ),
            InfoDetailTile(
              icon: LucideIcons.activity,
              label: "Active Governors",
              value: govs.isEmpty ? "Unknown" : govs,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const InfoDetailTile(
        icon: LucideIcons.alertTriangle,
        label: "Processor",
        value: "Communication Error",
      ),
    );
  }
}
