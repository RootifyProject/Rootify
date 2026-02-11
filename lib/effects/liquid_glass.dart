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
import 'dart:ui';
import 'package:flutter/material.dart';

// ---- MAJOR ---
// Liquid Glass Effect
class LiquidGlass extends StatelessWidget {
  // --- Parameters
  final Widget child;
  final double sigmaX;
  final double sigmaY;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
  });

  // --- Build
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // --- Color Logic
    // If color is explicitly provided, use it. Otherwise default to semantic surface shine.
    final shineColor = color ?? colorScheme.onSurface;

    // --- Content Layout
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // --- Visual Gloss
        // Optimized Liquid Glass gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            shineColor.withValues(alpha: isDark ? 0.15 : 0.08), // Highlight
            shineColor.withValues(alpha: isDark ? 0.02 : 0.01), // Bottom fade
          ],
        ),
        border: border,
      ),
      child: child,
    );

    // --- Optimization
    // If sigma is 0 (Blur Disabled), skip BackdropFilter completely
    if (sigmaX == 0 && sigmaY == 0) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: content,
      );
    }

    // --- Filter Logic
    // Apply clipping and backdrop filter
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: content,
      ),
    );
  }
}
