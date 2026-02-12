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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../providers/fpsgo_provider.dart';
import '../../shell/shell_fpsgo.dart';
import '../widgets/fpsgo_background.dart';
import '../widgets/fpsgo_profile_list.dart';
import '../widgets/fpsgo_parameter_group.dart';
import '../widgets/fpsgo_not_supported_view.dart';
import '../statusbar/sb_fpsgo.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';

// ---- MAJOR ---
// Advanced Game Engine Tuning & Real-time Scheduling
class FpsGoPage extends ConsumerStatefulWidget {
  const FpsGoPage({super.key});

  @override
  ConsumerState<FpsGoPage> createState() => _FpsGoPageState();
}

class _FpsGoPageState extends ConsumerState<FpsGoPage> {
  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & State
    final theme = Theme.of(context);
    final state = ref.watch(fpsGoStateProvider);
    final notifier = ref.read(fpsGoStateProvider.notifier);
    final topPadding = MediaQuery.of(context).padding.top;

    // --- Sub
    // Categorize parameters for cleaner UI
    final groupedParams = _groupParameters(state.parameters);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- Sub
          // 1. Morphing Background
          const FpsGoBackground(),

          // --- Sub
          // 2. Main Scroll Content
          if (state.isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (!state.isPlatformSupported)
            FpsGoNotSupportedView(onExit: () => Navigator.pop(context))
          // --- Sub
          // 2. Main Scrolling Content
          else
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Detail: Header Space
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 80)),

                // Detail: Header Title & Global Boot Toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("FPSGO",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                      color: theme.colorScheme.primary)),
                              const SizedBox(height: 4),
                              Text(
                                _getProfileName(state.currentMode),
                                style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    letterSpacing: 0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Detail: Apply on Boot Toggle (Standardized Width)
                        SizedBox(
                          width: 215,
                          child: RootifySubCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.power,
                                      size: 14,
                                      color: state.isApplyOnBootEnabled
                                          ? theme.colorScheme.primary
                                          : theme.hintColor,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Apply on Boot",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: state.isApplyOnBootEnabled,
                                    onChanged: (val) async {
                                      HapticFeedback.lightImpact();
                                      final dismiss = RootifyToast.showLoading(
                                          context, "Synchronizing...");
                                      try {
                                        await notifier.toggleApplyOnBoot(val);
                                        dismiss();
                                        if (context.mounted) {
                                          RootifyToast.success(context,
                                              "Apply on Boot ${val ? 'enabled' : 'disabled'} for FPSGO");
                                        }
                                      } catch (e) {
                                        dismiss();
                                        if (context.mounted) {
                                          RootifyToast.error(
                                              context, "Failed: $e");
                                        }
                                      }
                                    },
                                    activeTrackColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.5),
                                    activeThumbColor: theme.colorScheme.primary,
                                    inactiveTrackColor: theme
                                        .colorScheme.outline
                                        .withValues(alpha: 0.2),
                                    inactiveThumbColor:
                                        theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Detail: Mode Selection
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  sliver: SliverToBoxAdapter(
                    child: FpsGoProfileList(
                      currentMode: state.currentMode,
                      onSelect: (mode, title) async {
                        HapticFeedback.mediumImpact();
                        try {
                          await notifier.setMode(mode);
                          if (context.mounted) {
                            RootifyToast.success(
                                context, "Profile applied: $title");
                          }
                        } catch (e) {
                          if (context.mounted) {
                            RootifyToast.error(context,
                                "Failed to apply profile: ${e.toString().replaceFirst('Exception: ', '')}");
                          }
                        }
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Detail: Functional Parameters Section
                if (state.parameters.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Icon(LucideIcons.sliders,
                              size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Text("FINE TUNING",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: theme.colorScheme.secondary)),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),

                  // Detail: Dynamic Property Groups
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = groupedParams.keys.elementAt(index);
                          final params = groupedParams[category]!;
                          return FpsGoParameterGroup(
                            title: category,
                            params: params,
                            state: state,
                            notifier: notifier,
                          )
                              .animate()
                              .fadeIn(delay: (100 * index).ms)
                              .slideX(begin: 0.1);
                        },
                        childCount: groupedParams.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

          // --- Sub
          // 3. Floating Status Bar
          Positioned(
            top: topPadding + 10,
            left: 0,
            right: 0,
            child: const FpsGoStatusBar(),
          ),
        ],
      ),
    );
  }

  // ---- HELPERS ---

  Map<String, List<FpsGoParameter>> _groupParameters(
      List<FpsGoParameter> params) {
    final Map<String, List<FpsGoParameter>> groups = {};
    for (final p in params) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }
    return groups;
  }

  String _getProfileName(String mode) {
    switch (mode.toLowerCase()) {
      case 'default':
        return 'Default System';
      case 'recommended':
        return 'Adaptive Gaming';
      case 'performance':
        return 'Max Performance';
      case 'balanced':
        return 'Power Saver';
      case 'userspace':
        return 'UserSpace';
      default:
        return mode.toUpperCase();
    }
  }
}
