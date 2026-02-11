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

// ---- LOCAL ---
import 'blur_gaussian.dart';
import 'blur_mica.dart';
import 'blur_navy.dart';
import 'liquid_glass.dart';
import '../theme/theme_provider.dart';

// ---- MAJOR ---
// Rootify Blur Gatekeeper
class RootifyBlur extends ConsumerWidget {
  // --- Parameters
  final Widget child;
  final BlurCategory category;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry padding;

  const RootifyBlur({
    super.key,
    required this.child,
    required this.category,
    this.color,
    this.borderRadius,
    this.border,
    this.padding = EdgeInsets.zero,
  });

  // --- Build
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    // --- Performance Optimization
    // If blur is OFF for this category, return solid container (Fastest)
    if (!themeState.shouldBlur(category)) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainer,
          borderRadius: borderRadius,
          border: border,
        ),
        child: child,
      );
    }

    // --- Setup Filter Data
    final sigma = themeState.getSigmaFor(category);
    final clampedSigma = sigma.clamp(0.0, 12.0); // Safety Clamp

    // --- Build Content
    Widget content = padding != EdgeInsets.zero
        ? Padding(padding: padding, child: child)
        : child;

    Widget blurred;

    // --- Style Dispatcher
    switch (themeState.blurStyle) {
      case AppBlurStyle.gaussian:
        blurred = BlurGaussian(
          sigma: clampedSigma,
          borderRadius: borderRadius,
          border: border,
          child: content,
        );
        break;
      case AppBlurStyle.mica:
        blurred = BlurMica(
          sigma: clampedSigma,
          borderRadius: borderRadius,
          border: border,
          child: content,
        );
        break;
      case AppBlurStyle.navy:
        blurred = BlurNavy(
          sigma: clampedSigma,
          borderRadius: borderRadius,
          border: border,
          child: content,
        );
        break;
      case AppBlurStyle.liquid:
        blurred = LiquidGlass(
          sigmaX: clampedSigma,
          sigmaY: clampedSigma,
          opacity: theme.brightness == Brightness.dark ? 0.4 : 0.7,
          color: color ?? Colors.white,
          borderRadius: borderRadius ?? BorderRadius.zero,
          border: border,
          child: content,
        );
        break;
    }

    // --- Perspective & Repaint Isolation
    return RepaintBoundary(child: blurred);
  }
}
