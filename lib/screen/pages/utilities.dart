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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import 'rootifylog.dart';
import 'fps_meter.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';

// ---- MAJOR ---
// System Maintenance, Performance Monitoring, and Diagnostic Utility Hub
class UtilitiesPage extends ConsumerWidget {
  const UtilitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            key: const PageStorageKey('utilities_page_scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Cache Cleaner
                    RootifyCard(
                      title: "Maintenance",
                      subtitle: "System Cleanup Tools",
                      icon: LucideIcons.trash2,
                      child: RootifySubCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          RootifyToast.show(context, "Coming Soon",
                              icon: LucideIcons.hourglass);
                        },
                        child: _buildUtilityRow(
                          context,
                          title: "Cache Cleaner",
                          description: "Free up storage by clearing app cache",
                          icon: LucideIcons.trash2,
                        ),
                      ),
                    ),

                    // FPS Meter
                    RootifyCard(
                      title: "FPS Meter",
                      subtitle: "Performance Visualization",
                      icon: LucideIcons.gauge,
                      child: RootifySubCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FpsMeterPage(),
                            ),
                          );
                        },
                        child: _buildUtilityRow(
                          context,
                          title: "FPS Meter",
                          description:
                              "Floating performance monitor for gaming",
                          icon: LucideIcons.gauge,
                        ),
                      ),
                    ),

                    // System Logs / Live Logs
                    RootifyCard(
                      title: "Logging",
                      subtitle: "System Event Analysis",
                      icon: LucideIcons.fileSearch,
                      child: RootifySubCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RootifyLogPage()));
                        },
                        child: _buildUtilityRow(
                          context,
                          title: "System Logs",
                          description: "Real-time event and debugger outputs",
                          icon: LucideIcons.fileSearch,
                        ),
                      ),
                    ),

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

  // ---- HELPER BUILDERS ---

  Widget _buildUtilityRow(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
