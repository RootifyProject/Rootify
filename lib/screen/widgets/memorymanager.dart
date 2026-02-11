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
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Dashboard Entry Card for Memory Management Portal
class MemoryManagerCard extends StatelessWidget {
  final VoidCallback onTap;

  const MemoryManagerCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);

    // --- Component Assembly
    return RootifyCard(
      title: "Memory Manager",
      subtitle: "Dynamic RAM expansion & virtual memory tuning.",
      icon: LucideIcons.hardDrive,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Sub
          // Primary Action Label
          const Row(
            children: [
              RootifyIconBadge(icon: LucideIcons.settings2),
              SizedBox(width: 16),
              Text("ZRAM Tweaking",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),

          // --- Sub
          // Navigation Indicator
          Icon(LucideIcons.chevronRight,
              size: 20, color: theme.hintColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
