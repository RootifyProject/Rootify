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
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../../widgets/cards.dart';

// ---- MAJOR ---
// Branded Metadata & Asset Viewer
class DetailsPage extends StatelessWidget {
  // ---- STATEFUL PARAMETERS ---
  final String title;
  final String assetPath;
  final IconData icon;

  const DetailsPage({
    super.key,
    required this.title,
    required this.assetPath,
    required this.icon,
  });

  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // --- Sub
            // 1. Mirrored Dynamic Mesh Background
            Positioned.fill(
              child: Container(
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
                    // Primary Glow Effect
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
                              colorScheme.primary.withValues(alpha: 0.1),
                              colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(30, -30),
                          end: const Offset(-30, 30),
                          duration: 12.seconds),
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
                // Feature App Bar
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor:
                          isDarkMode ? Colors.black26 : Colors.white54,
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Center(
                      child: Opacity(
                        opacity: 0.4,
                        child: Icon(
                          icon,
                          size: 80,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Documentation Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 32),
                        RootifySubCard(
                          padding: const EdgeInsets.all(20),
                          child: FutureBuilder<String>(
                            future: rootBundle.loadString(assetPath),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text(
                                    "Error loading license content.");
                              }
                              return Text(
                                snapshot.data ?? "",
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                  fontFamily: 'monospace',
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
