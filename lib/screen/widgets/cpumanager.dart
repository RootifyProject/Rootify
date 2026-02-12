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
import '../../providers/cpu_provider.dart';
import '../../widgets/cards.dart';
import '../pages-sub/cpu_manager.dart';

// ---- MAJOR ---
// Dashboard Entry Card for CPU Management
class CpuManagerCard extends ConsumerWidget {
  const CpuManagerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Configuration
    final theme = Theme.of(context);
    final cpuState = ref.watch(cpuStateProvider);

    // --- Component Assembly
    return RootifyCard(
      title: "CPU Manager",
      subtitle: "Optimize core frequencies and governors.",
      icon: LucideIcons.cpu,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CpuManagerPage()));
      },
      child: Column(
        children: [
          // --- Sub
          // Feature Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const RootifyIconBadge(icon: LucideIcons.settings2),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Core Clusters",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${cpuState.policies.length} Clusters Detected",
                          style:
                              TextStyle(color: theme.hintColor, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              Icon(LucideIcons.chevronRight,
                  size: 20, color: theme.hintColor.withValues(alpha: 0.5)),
            ],
          ),

          // --- Sub
          // Active Configuration Badges
          if (cpuState.policies.isNotEmpty) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cpuState.policies.map((policy) {
                final gov = cpuState.currentGovernors[policy] ?? "---";
                final id = policy.split('policy').last;
                return RootifyTagBadge(label: "L$id", value: gov.toUpperCase());
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
