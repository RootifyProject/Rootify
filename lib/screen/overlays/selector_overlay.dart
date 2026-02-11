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

// ---- MAJOR ---
// Glassy Selector Component
class GlassySelector extends StatelessWidget {
  // --- Fields
  final String label;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String Function(String)? tagFormatter;

  const GlassySelector({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onSelected,
    this.tagFormatter,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          ),
        ),
        InkWell(
          onTap: () => _showSelectionDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tagFormatter != null
                      ? tagFormatter!(currentValue)
                      : currentValue,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color),
                ),
                Icon(LucideIcons.chevronDown,
                    size: 16,
                    color: theme.iconTheme.color?.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Sub
  // Show Selection Dialog
  void _showSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            // Detail
            // Fixed Height Limit (50% screen)
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Select $label",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // List
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final option = options[index];
                        final isSelected =
                            option.toUpperCase() == currentValue.toUpperCase();
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: theme.primaryColor,
                                      width: 2.0,
                                    )
                                  : Border.all(
                                      color: theme.dividerColor
                                          .withValues(alpha: 0.1),
                                    ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tagFormatter != null
                                        ? tagFormatter!(option)
                                        : option,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.normal,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    LucideIcons.checkCircle2,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Close Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
