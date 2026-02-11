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

// ---- LOCAL ---
import '../../providers/fpsgo_provider.dart';
import '../../shell/shell_fpsgo.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';

// ---- MAJOR ---
// Categorized Parameter Tuning Interface for FPSGO
class FpsGoParameterGroup extends ConsumerWidget {
  final String title;
  final List<FpsGoParameter> params;
  final FpsGoState state;
  final FpsGoNotifier notifier;

  const FpsGoParameterGroup({
    super.key,
    required this.title,
    required this.params,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Component Assembly
    return RootifyCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sub
          // Iterative Parameter Tile Generation
          ...params.asMap().entries.map((entry) {
            final index = entry.key;
            final param = entry.value;
            final isLast = index == params.length - 1;

            return Column(
              children: [
                _buildTile(context, param),
                if (!isLast) const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- Sub
  // Dynamic Factory for UI Control Types
  Widget _buildTile(BuildContext context, FpsGoParameter param) {
    if (param.type == FpsGoParamType.toggle) {
      return FpsGoSwitchTile(
        param: param,
        value: state.parameterValues[param.path] == "1",
        onChanged: (v) => notifier.setParameter(param.path, v ? "1" : "0"),
      );
    } else if (param.type == FpsGoParamType.range) {
      return FpsGoRangeTile(
        param: param,
        rawValue: state.parameterValues[param.path] ?? "0",
        onChanged: (v) => notifier.setParameter(param.path, v),
      );
    } else {
      return FpsGoValueTile(
        param: param,
        value: state.parameterValues[param.path] ?? "",
        onEdit: (v) => notifier.setParameter(param.path, v),
      );
    }
  }
}

// ---- MAJOR ---
// Binary Toggle Controller
class FpsGoSwitchTile extends StatelessWidget {
  final FpsGoParameter param;
  final bool value;
  final Function(bool) onChanged;

  const FpsGoSwitchTile(
      {super.key,
      required this.param,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);

    // --- Component Assembly
    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Detail: Label Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(param.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(param.description,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          // Detail: Interaction Switch
          Switch(
              value: value,
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              activeThumbColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
              onChanged: (v) async {
                HapticFeedback.lightImpact();
                try {
                  await onChanged(v);
                  if (context.mounted) {
                    RootifyToast.success(context, "${param.name} updated");
                  }
                } catch (e) {
                  if (context.mounted) {
                    RootifyToast.error(
                        context, "Failed to update ${param.name}");
                  }
                }
              }),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Linear Frequency/Limit Controller
class FpsGoRangeTile extends StatelessWidget {
  final FpsGoParameter param;
  final String rawValue;
  final Function(String) onChanged;

  const FpsGoRangeTile(
      {super.key,
      required this.param,
      required this.rawValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final min = param.min ?? 0.0;
    final max = param.max ?? 100.0;
    final val = double.tryParse(rawValue) ?? min;

    // --- Component Assembly
    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail: Metric Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(param.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text(val.toInt().toString(),
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 8),

          // Detail: Analog Slider Persistence
          SliderTheme(
            data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                thumbColor: theme.colorScheme.primary),
            child: Slider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).toInt() > 0 ? (max - min).toInt() : 1,
              onChanged: (v) => onChanged(v.toInt().toString()),
            ),
          ),
          Text(param.description,
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Numeric Data Entry Controller
class FpsGoValueTile extends StatelessWidget {
  final FpsGoParameter param;
  final String value;
  final Function(String) onEdit;

  const FpsGoValueTile(
      {super.key,
      required this.param,
      required this.value,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);

    // --- Component Assembly
    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => _showEditDialog(context),
      child: Row(
        children: [
          // Detail: Label Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(param.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(param.description,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),

          // Detail: Current Value Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              value.isEmpty ? "..." : value,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Numeric Modal Entry Interface
  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(param.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: "Value",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            helperText: "Enter a valid integer value",
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
              onPressed: () {
                onEdit(controller.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text("Apply")),
        ],
      ),
    );
  }
}
