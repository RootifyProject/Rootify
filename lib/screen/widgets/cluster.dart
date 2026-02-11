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
import '../../services/cpu.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';

// ---- MAJOR ---
// Core Cluster Frequency and Governor Control Card
class ClusterControlCard extends ConsumerWidget {
  final String policy;

  const ClusterControlCard({super.key, required this.policy});

  // --- Sub
  // Frequency Label Formatting
  String _formatFreq(String freq) {
    if (freq.isEmpty || freq == "Unknown") return "Unknown";
    try {
      final khz = int.parse(freq);
      if (khz > 1000000) return "${(khz / 1000000).toStringAsFixed(1)} GHz";
      return "${khz ~/ 1000} MHz";
    } catch (e) {
      return freq;
    }
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Configuration
    final clusterId = policy.split('policy').last;
    final clusterName = "CLUSTER $clusterId";

    final currentGov = ref.watch(cpuStateProvider
        .select((s) => s.currentGovernors[policy] ?? "Unknown"));
    final minFreq =
        ref.watch(cpuStateProvider.select((s) => s.minFreqs[policy] ?? "0"));
    final maxFreq =
        ref.watch(cpuStateProvider.select((s) => s.maxFreqs[policy] ?? "0"));

    final govSelected = ref.watch(
        cpuStateProvider.select((s) => s.selectedGovernors[policy] ?? true));
    final minSelected = ref.watch(
        cpuStateProvider.select((s) => s.selectedMinFreqs[policy] ?? true));
    final maxSelected = ref.watch(
        cpuStateProvider.select((s) => s.selectedMaxFreqs[policy] ?? true));

    final availableGovs =
        ref.read(cpuStateProvider).availableGovernors[policy] ?? [];
    final availableFreqs =
        ref.read(cpuStateProvider).availableFrequencies[policy] ?? [];

    // --- Component Assembly
    return RootifyCard(
      title: clusterName,
      icon: LucideIcons.cpu,
      child: Column(
        children: [
          // --- Sub
          // Realtime Logic Metrics
          RootifySubCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Realtime Frequency",
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _RealtimeFreqBadge(policy: policy),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Sub
          // Scaling Governor Selection
          _buildGovernorSelector(
              context, ref, currentGov, availableGovs, govSelected),

          const SizedBox(height: 16),

          // --- Sub
          // Frequency Boundary Configuration
          Row(
            children: [
              Expanded(
                child: _FreqColumn(
                  label: "Min Frequency",
                  value: minFreq,
                  options: availableFreqs,
                  color: const Color(0xFF2196F3),
                  onSelected: (val) async {
                    try {
                      await ref
                          .read(cpuStateProvider.notifier)
                          .setMinFreq(policy, val);
                      if (context.mounted) {
                        RootifyToast.success(
                            context, "Min freq set to ${_formatFreq(val)}");
                      }
                    } catch (e) {
                      if (context.mounted) {
                        RootifyToast.error(context, "Failed to set min freq");
                      }
                    }
                  },
                  formatFunc: _formatFreq,
                  isSelected: minSelected,
                  onToggleBoot: () => ref
                      .read(cpuStateProvider.notifier)
                      .toggleMinFreqSelection(policy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FreqColumn(
                  label: "Max Frequency",
                  value: maxFreq,
                  options: availableFreqs,
                  color: const Color(0xFFFF5252),
                  onSelected: (val) async {
                    try {
                      await ref
                          .read(cpuStateProvider.notifier)
                          .setMaxFreq(policy, val);
                      if (context.mounted) {
                        RootifyToast.success(
                            context, "Max freq set to ${_formatFreq(val)}");
                      }
                    } catch (e) {
                      if (context.mounted) {
                        RootifyToast.error(context, "Failed to set max freq");
                      }
                    }
                  },
                  formatFunc: _formatFreq,
                  isSelected: maxSelected,
                  onToggleBoot: () => ref
                      .read(cpuStateProvider.notifier)
                      .toggleMaxFreqSelection(policy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Governor Interaction Logic
  Widget _buildGovernorSelector(BuildContext context, WidgetRef ref,
      String currentGov, List<String> availableGovs, bool isSelected) {
    final theme = Theme.of(context);
    return RootifySubCard(
      onTap: () => showSelectorOverlay(
        context: context,
        title: "Governor Profile",
        currentValue: currentGov.toUpperCase(),
        options: availableGovs,
        accentColor: theme.colorScheme.primary,
        bootSelection: isSelected,
        onToggleBoot: () =>
            ref.read(cpuStateProvider.notifier).toggleGovernorSelection(policy),
        onSelected: (val) async {
          try {
            await ref.read(cpuStateProvider.notifier).setGovernor(policy, val);
            if (context.mounted) {
              RootifyToast.success(context, "Governor set to $val");
            }
          } catch (e) {
            if (context.mounted) {
              RootifyToast.error(context, "Failed to apply governor");
            }
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text("Governor Profile".toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentGov.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace',
                      letterSpacing: -0.5)),
              const Icon(LucideIcons.chevronUp, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Horizontal Frequency Selection Column
class _FreqColumn extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final String Function(String) formatFunc;
  final Color color;
  final bool isSelected;
  final VoidCallback onToggleBoot;

  const _FreqColumn({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.formatFunc,
    required this.color,
    required this.isSelected,
    required this.onToggleBoot,
  });

  @override
  Widget build(BuildContext context) {
    return RootifySubCard(
      padding: const EdgeInsets.all(12),
      onTap: () => showSelectorOverlay(
          context: context,
          title: "Select $label",
          options: options,
          currentValue: value,
          accentColor: color,
          bootSelection: isSelected,
          onToggleBoot: onToggleBoot,
          onSelected: onSelected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(formatFunc(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        fontFamily: 'Monospace')),
              ),
              const Icon(LucideIcons.chevronUp, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Dynamic Frequency Monitoring Badge
class _RealtimeFreqBadge extends ConsumerWidget {
  final String policy;
  const _RealtimeFreqBadge({required this.policy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Configuration
    final snapshot = ref.watch(cpuMonitorStreamProvider).value;

    int freqMhz = 0;
    if (snapshot != null) {
      final clusterName = policy.split('/').last;
      final clusterId =
          int.tryParse(clusterName.replaceFirst('policy', '')) ?? -1;
      final cluster = snapshot.clusters.firstWhere((c) => c.id == clusterId,
          orElse: () => CpuCluster(-1, []));

      if (cluster.id != -1 && cluster.coreIds.isNotEmpty) {
        final firstCoreId = cluster.coreIds.first;
        final core = snapshot.cores.firstWhere((c) => c.id == firstCoreId);
        freqMhz = core.mhz;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Component Assembly
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Detail: Heartbeat Animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.2, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, val, _) {
              return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: val),
                      shape: BoxShape.circle));
            },
          ),
          const SizedBox(width: 8),
          Text('$freqMhz MHz',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                  color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Global Selection Overlay Interface
Future<void> showSelectorOverlay({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String currentValue,
  required ValueChanged<String> onSelected,
  bool? bootSelection,
  VoidCallback? onToggleBoot,
  Color? accentColor,
}) {
  final theme = Theme.of(context);
  final activeColor = accentColor ?? theme.primaryColor;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (context, setLocalState) {
        final isSelectedBoot = bootSelection ?? true;

        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              // Detail: Contextual Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: theme.hintColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail: Interactive Option List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected =
                        option.toLowerCase() == currentValue.toLowerCase();

                    return InkWell(
                      onTap: () {
                        if (isSelected && onToggleBoot != null) {
                          setLocalState(() {
                            onToggleBoot();
                            bootSelection = !(bootSelection ?? true);
                          });
                          HapticFeedback.lightImpact();
                        } else {
                          onSelected(option);
                          Navigator.pop(ctx);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.1)
                              : theme.cardColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? activeColor
                                  : theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(option,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontFamily: 'Monospace',
                                    color: isSelected
                                        ? activeColor
                                        : theme.textTheme.bodyLarge?.color)),
                            Icon(
                                isSelected
                                    ? (isSelectedBoot
                                        ? LucideIcons.checkCircle2
                                        : LucideIcons.circle)
                                    : LucideIcons.circle,
                                color: isSelected
                                    ? activeColor
                                    : theme.hintColor.withValues(alpha: 0.2),
                                size: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
