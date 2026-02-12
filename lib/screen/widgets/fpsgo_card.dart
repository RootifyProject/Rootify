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
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../providers/fpsgo_provider.dart';
import '../../widgets/cards.dart';
import '../pages-sub/fpsgo.dart';

// ---- MAJOR ---
// Dashboard Entry Card for FPSGO Management
class FpsGoCard extends ConsumerWidget {
  const FpsGoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Configuration
    final state = ref.watch(fpsGoStateProvider);
    final theme = Theme.of(context);

    if (!state.isPlatformSupported) return const SizedBox.shrink();

    // --- Component Assembly
    if (!state.isSupported) {
      return RootifyCard(
        title: "FPSGO",
        subtitle: "Hardware Not Supported",
        icon: LucideIcons.gauge,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle,
                  size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "FPSGO requires a MediaTek kernel with perfmgr support. This feature is not available on your device.",
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RootifyCard(
      title: "FPSGO",
      subtitle: "MediaTek frame-aware power management.",
      icon: LucideIcons.gauge,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const FpsGoPage()));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Sub
          // Profile Indicator Context
          Row(
            children: [
              RootifyIconBadge(
                  icon: LucideIcons.gauge, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Current Profile",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(state.currentMode.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ],
          ),

          // --- Sub
          // Navigation Escape
          Icon(LucideIcons.chevronRight,
              size: 20, color: theme.hintColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
