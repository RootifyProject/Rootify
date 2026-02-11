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
import '../../shell/shell_zram.dart';
import 'statusbar.dart';

// ---- MAJOR ---
// Memory Management Specialized Status Bar
class MemoryStatusBar extends ConsumerWidget {
  const MemoryStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Feature Title & Dynamic Metrics
    return SystemStatusBar(
      title: "MEMORY",
      showBackButton: true,
      customTitle: Consumer(
        builder: (context, ref, child) {
          final zramShell = ref.watch(zramShellProvider);
          final colorScheme = Theme.of(context).colorScheme;

          return FutureBuilder<int>(
            future: zramShell.getZramSize(),
            builder: (context, snapshot) {
              final size = snapshot.data ?? 0;
              final isActive = size > 0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.hardDrive,
                      size: 14,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  const Text("MEMORY",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                  if (isActive) ...[
                    Container(
                        width: 1.5,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: colorScheme.outlineVariant),
                    Text("${size}MB",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: colorScheme.primary)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
