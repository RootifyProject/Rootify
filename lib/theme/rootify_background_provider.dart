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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import 'theme_provider.dart';

// ---- MAJOR ---
// Background One (Aurora Gradient Style)
class BackgroundOneMainPage extends StatelessWidget {
  final Widget child;

  const BackgroundOneMainPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          // Primary Glow (Top-Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
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
                begin: const Offset(-30, 30),
                end: const Offset(30, -30),
                duration: 12.seconds),
          ),
          // Secondary Glow (Bottom-Left)
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.08),
                    colorScheme.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                begin: const Offset(30, -30),
                end: const Offset(-30, 30),
                duration: 10.seconds),
          ),
          child,
        ],
      ),
    );
  }
}

// ---- Sub ---
// Background One: Sub Page Variant
class BackgroundOneSubPage extends StatelessWidget {
  final Widget child;

  const BackgroundOneSubPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          // Primary Glow (Top-Left)
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
          // Secondary Glow (Bottom-Right)
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
          child,
        ],
      ),
    );
  }
}

// --- MAJOR ---
// Background Two (Material Design 3 Style - Solid)
class BackgroundTwoMainPage extends StatelessWidget {
  final Widget child;

  const BackgroundTwoMainPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final solidBackgroundColor = isDarkMode
        ? colorScheme.surface
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.04),
            colorScheme.surface,
          );

    return Container(
      color: solidBackgroundColor,
      child: child,
    );
  }
}

class BackgroundTwoSubPage extends StatelessWidget {
  final Widget child;

  const BackgroundTwoSubPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final solidBackgroundColor = isDarkMode
        ? colorScheme.surface
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.04),
            colorScheme.surface,
          );

    return Container(
      color: solidBackgroundColor,
      child: child,
    );
  }
}

// --- MAJOR ---
// Dynamic Background Switchers
class RootifyMainBackground extends ConsumerWidget {
  final Widget child;

  const RootifyMainBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: themeState.visualStyle == AppVisualStyle.aurora
          ? BackgroundOneMainPage(key: const ValueKey('bg1_main'), child: child)
          : BackgroundTwoMainPage(
              key: const ValueKey('bg2_main'), child: child),
    );
  }
}

class RootifySubBackground extends ConsumerWidget {
  final Widget child;

  const RootifySubBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: themeState.visualStyle == AppVisualStyle.aurora
          ? BackgroundOneSubPage(key: const ValueKey('bg1_sub'), child: child)
          : BackgroundTwoSubPage(key: const ValueKey('bg2_sub'), child: child),
    );
  }
}
