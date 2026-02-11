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
// Primary ZRAM Capacity Configuration Interface
class ZramAllocationCard extends StatelessWidget {
  final int totalRamMB;
  final double sliderValue;
  final double safeLimitMB;
  final double hardLimitMB;
  final bool isUnlocked;
  final TextEditingController controller;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onUnlock;

  const ZramAllocationCard({
    super.key,
    required this.totalRamMB,
    required this.sliderValue,
    required this.safeLimitMB,
    required this.hardLimitMB,
    required this.isUnlocked,
    required this.controller,
    required this.onSliderChanged,
    required this.onTextChanged,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentMax = isUnlocked ? hardLimitMB : safeLimitMB;

    // --- Component Assembly
    return RootifyCard(
      title: "ZRAM Allocation",
      subtitle: "Expand physical RAM with compressed virtual memory.",
      icon: LucideIcons.hardDrive,
      child: Column(
        children: [
          // --- Sub
          // Capacity Distribution Bar
          _buildVisualBar(theme),
          const SizedBox(height: 16),

          // --- Sub
          // Digital Input Context
          _buildDigitalInput(theme, isDarkMode),
          const SizedBox(height: 16),

          // --- Sub
          // Analog Slider Control
          _buildAllocationSlider(theme, currentMax),

          // --- Sub
          // Unlock Action Persistence
          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            _buildUnlockButton(context),
          ],
        ],
      ),
    );
  }

  // ---- INTERNAL HELPERS ---

  // --- Sub
  // RAM to Swap Visualizer
  Widget _buildVisualBar(ThemeData theme) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Detail: Physical RAM Segment
          Expanded(
            flex: totalRamMB,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.4),
                  theme.colorScheme.primary.withValues(alpha: 0.2)
                ]),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(6)),
              ),
            ),
          ),
          // Detail: ZRAM Allocated Segment
          Expanded(
            flex: sliderValue.toInt(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  isUnlocked ? Colors.orange : theme.colorScheme.primary,
                  (isUnlocked ? Colors.orange : theme.colorScheme.primary)
                      .withValues(alpha: 0.6)
                ]),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                      color: (isUnlocked
                              ? Colors.orange
                              : theme.colorScheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 4)
                ],
              ),
            ),
          ),
          // Detail: Remaining Capability Buffer
          Expanded(
            flex: (hardLimitMB - totalRamMB - sliderValue.toInt())
                .toInt()
                .clamp(1, hardLimitMB.toInt()),
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Numeric Data Entry
  Widget _buildDigitalInput(ThemeData theme, bool isDarkMode) {
    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TARGET SIZE",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text("${sliderValue.toInt()} MB",
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Monospace')),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDarkMode ? Colors.black26 : Colors.white10,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                suffixText: "MB",
              ),
              onChanged: onTextChanged,
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Range Adjustment Control
  Widget _buildAllocationSlider(ThemeData theme, double currentMax) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Allocation", style: theme.textTheme.labelMedium),
            Text(isUnlocked ? "UNLOCKED (Max 3x)" : "SAFE (Max 2x)",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor:
                isUnlocked ? Colors.orange : theme.colorScheme.primary,
            inactiveTrackColor:
                (isUnlocked ? Colors.orange : theme.colorScheme.primary)
                    .withValues(alpha: 0.15),
            thumbColor: isUnlocked ? Colors.orange : theme.colorScheme.primary,
            overlayColor:
                (isUnlocked ? Colors.orange : theme.colorScheme.primary)
                    .withValues(alpha: 0.12),
          ),
          child: Slider(
            value: sliderValue.clamp(0, currentMax),
            min: 0,
            max: currentMax,
            divisions: currentMax > 0 ? (currentMax / 128).ceil() : 100,
            onChanged: onSliderChanged,
          ),
        ),
      ],
    );
  }

  // --- Sub
  // Limit Elevation Trigger
  Widget _buildUnlockButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onUnlock,
        icon: const Icon(LucideIcons.lock, size: 14),
        label: const Text("Unlock Limit (Risk of Lags)"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }
}
