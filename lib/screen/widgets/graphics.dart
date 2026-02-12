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
import '../../services/gpu.dart';
import '../../widgets/cards.dart';
import 'info_widgets.dart';

// ---- MAJOR ---
// Graphics (GPU) Information Section
// --- GraphicsSection
class GraphicsSection extends ConsumerWidget {
  const GraphicsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);

    return RootifyCard(
      title: "Graphics",
      icon: LucideIcons.monitor,
      child: _GpuInfo(theme: theme, ref: ref),
    );
  }
}

// Supporting widget for GPU metadata rendering
// --- GpuInfo
class _GpuInfo extends StatelessWidget {
  final ThemeData theme;
  final WidgetRef ref;

  const _GpuInfo({
    required this.theme,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // GPU Provider
    final gpuInfoAsync = ref.watch(gpuInfoProvider);

    return gpuInfoAsync.when(
      data: (gpu) => Column(
        children: [
          InfoDetailTile(
            icon: LucideIcons.factory,
            label: "Vendor",
            value: gpu.vendor,
          ),
          InfoDetailTile(
            icon: LucideIcons.component,
            label: "Renderer",
            value: gpu.renderer,
          ),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const InfoDetailTile(
        icon: LucideIcons.alertTriangle,
        label: "GPU Info",
        value: "Unavailable",
      ),
    );
  }
}
