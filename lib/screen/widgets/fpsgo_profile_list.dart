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
import '../../widgets/toast.dart';

// ---- MAJOR ---
// Vertical List of Selectable FPSGO Operation Profiles
class FpsGoProfileList extends StatelessWidget {
  final String currentMode;
  final Function(String, String) onSelect;

  const FpsGoProfileList(
      {super.key, required this.currentMode, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // --- Component Assembly
    return Column(
      children: [
        // --- Sub
        // Profile Item Persistence
        FpsGoProfileCard(
          id: "default",
          title: "Default System",
          desc: "Factory configuration. Balanced daily usage.",
          icon: LucideIcons.smartphone,
          isSelected: currentMode == "default",
          onTap: () => onSelect("default", "Default System"),
        ),
        const SizedBox(height: 4),
        FpsGoProfileCard(
          id: "recommended",
          title: "Adaptive Gaming",
          desc: "Optimized FBT nodes for stability & thermals.",
          icon: LucideIcons.gamepad2,
          isSelected: currentMode == "recommended",
          isBest: true,
          onTap: () => onSelect("recommended", "Adaptive Gaming"),
        ),
        const SizedBox(height: 4),
        FpsGoProfileCard(
          id: "performance",
          title: "Max Performance",
          desc: "Aggressive frequency scaling. Ignores efficiency.",
          icon: LucideIcons.zap,
          isSelected: currentMode == "performance",
          onTap: () => onSelect("performance", "Max Performance"),
        ),
        const SizedBox(height: 4),
        FpsGoProfileCard(
          id: "balanced",
          title: "Power Saver",
          desc: "Conservative scaling favoring battery life.",
          icon: LucideIcons.batteryMedium,
          isSelected: currentMode == "balanced",
          onTap: () => onSelect("balanced", "Power Saver"),
        ),
        const SizedBox(height: 4),

        // --- Sub
        // Manual Tuning Mode Lifecycle
        Opacity(
          opacity: currentMode == "userspace" ? 1.0 : 0.5,
          child: FpsGoProfileCard(
            id: "userspace",
            title: "UserSpace / Manual",
            desc: "Custom tuning. Activated by editing parameters below.",
            icon: LucideIcons.wrench,
            isSelected: currentMode == "userspace",
            onTap: currentMode == "userspace"
                ? () {
                    HapticFeedback.lightImpact();
                    RootifyToast.show(context, "UserSpace is active");
                  }
                : () {
                    HapticFeedback.lightImpact();
                    RootifyToast.show(
                        context, "Modify a parameter to activate");
                  },
          ),
        ),
      ],
    );
  }
}

// ---- MAJOR ---
// Individual Profile Selection Row
class FpsGoProfileCard extends StatelessWidget {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBest;

  const FpsGoProfileCard({
    super.key,
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    // --- Component Assembly
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: RootifySubCard(
          padding: const EdgeInsets.all(16),
          color: isSelected ? activeColor.withValues(alpha: 0.1) : null,
          child: Row(
            children: [
              // Detail: Category Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isSelected ? Colors.white : theme.iconTheme.color),
              ),
              const SizedBox(width: 16),

              // Detail: Label Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        if (isBest) ...[
                          const SizedBox(width: 8),
                          _buildRecommendedBadge(),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),

              // Detail: Selection Indicator
              if (isSelected)
                Icon(LucideIcons.checkCircle2, color: activeColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub
  // Visual Hint for Recommended Setting
  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.amber, borderRadius: BorderRadius.circular(4)),
      child: const Text("RECOMMENDED",
          style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)),
    );
  }
}
