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
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../../providers/cpu_provider.dart';
import '../../screen/statusbar/sb_cpumanager.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import '../widgets/cluster.dart';

// ---- MAJOR ---
// CPU Frequency & Policy Management Page
class CpuManagerPage extends ConsumerStatefulWidget {
  const CpuManagerPage({super.key});

  @override
  ConsumerState<CpuManagerPage> createState() => _CpuManagerPageState();
}

class _CpuManagerPageState extends ConsumerState<CpuManagerPage> {
  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Lifecycle Monitoring
    ref.watch(cpuMonitorStreamProvider);

    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- Sub
          // 1. Mirrored Dynamic Mesh Background
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainer,
                    colorScheme.surfaceContainerHigh,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Detail: Primary Glow
                  Positioned(
                    top: -120,
                    left: -120,
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.15),
                            colorScheme.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                        begin: const Offset(30, -30),
                        end: const Offset(-30, 30),
                        duration: 12.seconds),
                  ),
                  // Detail: Secondary Glow
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.secondary.withValues(alpha: 0.1),
                            colorScheme.secondary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                        begin: const Offset(-30, 30),
                        end: const Offset(30, -30),
                        duration: 10.seconds),
                  ),
                ],
              ),
            ),
          ),

          // --- Sub
          // 2. Main Scrolling Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Detail: Header Space
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 80)),

              // Detail: Header Row (Text + Apply on Boot)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Detail: Page Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CPU",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    height: 1.0,
                                    color: theme.colorScheme.primary)),
                            Text("POLICIES",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    height: 1.0,
                                    color: theme.colorScheme.primary)),
                          ],
                        ),
                      ),
                      // Detail: Apply on Boot Toggle (Fixed Width)
                      SizedBox(
                        width: 215,
                        child: _buildApplyOnBootToggle(context, ref),
                      ),
                    ],
                  ),
                ),
              ),

              // Detail: Content Gap (Matches Tweaks 24px total)
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Detail: Dynamic Cluster Control Cards
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(cpuStateProvider);
                  if (state.isLoading) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ClusterControlCard(
                              policy: state.policies[index]);
                        },
                        childCount: state.policies.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // --- Sub
          // 3. Floating Status Bar
          Positioned(
            top: topPadding + 10,
            left: 0,
            right: 0,
            child: const CpuManagerStatusBar(),
          ),
        ],
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildApplyOnBootToggle(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Context & Theme
    final theme = Theme.of(context);
    final state = ref.watch(cpuStateProvider);

    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Detail: Label & Icon
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
          // Detail: Global Controller Toggle
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: state.isApplyOnBootEnabled,
              onChanged: (val) async {
                HapticFeedback.lightImpact();
                try {
                  await ref
                      .read(cpuStateProvider.notifier)
                      .toggleApplyOnBoot(val);
                  if (context.mounted) {
                    RootifyToast.success(context,
                        "Apply on Boot ${val ? 'enabled' : 'disabled'} for CPU Settings");
                  }
                } catch (e) {
                  if (context.mounted) {
                    RootifyToast.error(
                        context, e.toString().replaceFirst('Exception: ', ''));
                  }
                }
              },
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              activeThumbColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
