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
import '../../providers/fpsgo_provider.dart';
import 'statusbar.dart';

// ---- MAJOR ---
// FPS Tuning Specialized Status Bar
class FpsGoStatusBar extends ConsumerWidget {
  const FpsGoStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Feature Title & Activation Status
    return SystemStatusBar(
      title: "FPSGO",
      showBackButton: true,
      customTitle: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(fpsGoStateProvider);
          final colorScheme = Theme.of(context).colorScheme;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(LucideIcons.gauge, size: 16, color: colorScheme.primary),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.isEnabled
                            ? colorScheme.primary
                            : colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "FPSGO | ${state.currentMode.toUpperCase()}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
