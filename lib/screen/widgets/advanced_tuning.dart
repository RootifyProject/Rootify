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
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Kernel-Level Parameter Tuning Interface
class AdvancedTuningCard extends StatelessWidget {
  final List<String> availableAlgos;
  final String selectedAlgo;
  final double swappinessValue;
  final double vfsPressureValue;
  final ValueChanged<String> onAlgoSelected;
  final ValueChanged<double> onSwappinessChanged;
  final ValueChanged<double> onVfsPressureChanged;

  const AdvancedTuningCard({
    super.key,
    required this.availableAlgos,
    required this.selectedAlgo,
    required this.swappinessValue,
    required this.vfsPressureValue,
    required this.onAlgoSelected,
    required this.onSwappinessChanged,
    required this.onVfsPressureChanged,
  });

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // --- Component Assembly
    return RootifyCard(
      title: "Advanced Tuning",
      subtitle: "Fine-tune virtual memory management behavior.",
      icon: LucideIcons.sliders,
      child: Column(
        children: [
          // --- Sub
          // Compression Architecture Selection
          if (availableAlgos.isNotEmpty) ...[
            _buildCompressionAlgos(theme, isDarkMode),
            const SizedBox(height: 16),
          ],

          // --- Sub
          // Swap Management Persistence
          _buildSwappiness(theme),
          const SizedBox(height: 16),

          // --- Sub
          // File System Cache Reclaim Tuning
          _buildVfsPressure(theme),
        ],
      ),
    );
  }

  // ---- INTERNAL HELPERS ---

  // --- Sub
  // ZRAM Compression Selector
  Widget _buildCompressionAlgos(ThemeData theme, bool isDarkMode) {
    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("COMPRESSION ALGORITHM",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.0)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableAlgos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 48,
            ),
            itemBuilder: (context, index) {
              final algo = availableAlgos[index];
              final isSelected = selectedAlgo == algo;
              return InkWell(
                onTap: () => onAlgoSelected(algo),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(algo.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontFamily: 'Monospace',
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyLarge?.color)),
                      Icon(
                          isSelected
                              ? LucideIcons.checkCircle2
                              : LucideIcons.circle,
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.hintColor.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Memory Swap Aggressiveness Tuning
  Widget _buildSwappiness(ThemeData theme) {
    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SWAPPINESS",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0)),
                    SizedBox(height: 2),
                    Text("Swap aggressiveness", style: TextStyle(fontSize: 10))
                  ]),
              Text("${swappinessValue.toInt()}%",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
                value: swappinessValue,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: onSwappinessChanged),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Cache Pressure Ratio Adjustment
  Widget _buildVfsPressure(ThemeData theme) {
    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("VFS CACHE PRESSURE",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0)),
                    SizedBox(height: 2),
                    Text("Kernel cache reclaim policy",
                        style: TextStyle(fontSize: 10))
                  ]),
              Text("${vfsPressureValue.toInt()}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
                value: vfsPressureValue,
                min: 0,
                max: 1000,
                divisions: 200,
                onChanged: onVfsPressureChanged),
          ),
        ],
      ),
    );
  }
}
