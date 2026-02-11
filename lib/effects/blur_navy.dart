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
// Navy Blur Effect
class BlurNavy extends StatelessWidget {
  // --- Parameters
  final Widget child;
  final double sigma;
  final BorderRadius? borderRadius;
  final Border? border;

  const BlurNavy({
    super.key,
    required this.child,
    this.sigma = 10.0,
    this.borderRadius,
    this.border,
  });

  // --- Build
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // --- Navy Setup
    final navyBase = colorScheme.secondaryContainer;
    final navyHighlight = colorScheme.secondary;

    // --- Texture Layer
    // Second layer for depth feel
    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navyHighlight.withValues(alpha: isDark ? 0.3 : 0.1),
            navyBase.withValues(alpha: isDark ? 0.8 : 0.4),
          ],
        ),
        border: border,
      ),
      child: child,
    );

    // --- Optimization
    // Skip filter if disabled (sigma = 0)
    if (sigma == 0) {
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
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      ),
    );
  }
}
