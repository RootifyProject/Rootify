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
// Mica Blur Effect
class BlurMica extends StatelessWidget {
  // --- Parameters
  final Widget child;
  final double sigma;
  final BorderRadius? borderRadius;
  final Border? border;

  const BlurMica({
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

    // --- Filter Logic
    // Mica effect with multi-layered color and gradient
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: colorScheme.surfaceContainer.withValues(
              alpha: isDark ? 0.6 : 0.7,
            ),
            border: border,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.onSurface.withValues(alpha: isDark ? 0.03 : 0.01),
                colorScheme.onSurface.withValues(alpha: isDark ? 0.01 : 0.03),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
