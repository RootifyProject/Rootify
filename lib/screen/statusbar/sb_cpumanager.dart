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
import 'statusbar.dart';

// ---- MAJOR ---
// CPU Management Specialized Status Bar
class CpuManagerStatusBar extends ConsumerWidget {
  const CpuManagerStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Feature Title & Static Metrics
    return SystemStatusBar(
      title: "CPU MANAGER",
      showBackButton: true,
      customTitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.cpu,
              size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text("CPU MANAGER",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
