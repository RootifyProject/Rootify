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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../providers/cpu_provider.dart';
import '../../providers/fpsgo_provider.dart';
import '../../providers/shared_prefs_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import '../widgets/cpumanager.dart';
import '../widgets/memorymanager.dart';
import '../widgets/fpsgo_card.dart';
import '../pages-sub/memory_manager.dart';

// ---- MAJOR ---
// Unified Control Dashboard for Performance & Kernel Fine-Tuning
class TweaksPage extends ConsumerStatefulWidget {
  const TweaksPage({super.key});

  @override
  ConsumerState<TweaksPage> createState() => _TweaksPageState();
}

class _TweaksPageState extends ConsumerState<TweaksPage> {
  // ---- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cpuStateProvider.notifier).loadData();
      ref.read(fpsGoStateProvider.notifier).loadData();
    });
  }

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final colorScheme = Theme.of(context).colorScheme;
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
            key: const PageStorageKey('tweaks_page_scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const CpuManagerCard(),
                    MemoryManagerCard(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MemoryManagerPage()),
                        );
                      },
                    ),
                    const FpsGoCard(),
                    const _ThermalSection(),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- SUPPORTING COMPONENTS ---

class _ThermalSection extends ConsumerStatefulWidget {
  const _ThermalSection();
  @override
  ConsumerState<_ThermalSection> createState() => _ThermalSectionState();
}

class _ThermalSectionState extends ConsumerState<_ThermalSection> {
  bool _disabled = false;
  bool _applyOnBoot = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (mounted) {
      setState(() {
        _disabled = prefs.getBool('thermal_disabled') ?? false;
        _applyOnBoot = prefs.getBool('thermal_boot') ?? false;
      });
    }
  }

  Future<void> _toggle(bool val) async {
    HapticFeedback.lightImpact();
    RootifyToast.show(context, "Thermal Manager: Coming Soon!",
        icon: LucideIcons.hourglass);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RootifyCard(
      title: "Thermal Manager",
      subtitle: "Remove system thermal limits.",
      icon: LucideIcons.flame,
      child: Column(
        children: [
          RootifySubCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Disable Throttling",
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Switch(
                  value: _disabled,
                  onChanged: _toggle,
                  activeTrackColor:
                      theme.colorScheme.error.withValues(alpha: 0.5),
                  activeThumbColor: theme.colorScheme.error,
                  inactiveTrackColor:
                      theme.colorScheme.outline.withValues(alpha: 0.2),
                  inactiveThumbColor: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ApplyOnBootSwitch(
              value: _applyOnBoot,
              onChanged: (val) async {
                HapticFeedback.lightImpact();
                RootifyToast.show(context, "Coming Soon!",
                    icon: LucideIcons.hourglass);
              }),
        ],
      ),
    );
  }
}

class _ApplyOnBootSwitch extends ConsumerWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ApplyOnBootSwitch({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return RootifySubCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.power,
                size: 14,
                color: value ? theme.colorScheme.primary : theme.hintColor,
              ),
              const SizedBox(width: 12),
              const Text(
                "APPLY ON BOOT",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
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
