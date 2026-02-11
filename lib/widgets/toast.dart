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
import '../effects/rootify_blur.dart';
import '../theme/theme_provider.dart';
import '../animations/toast_animation.dart';
import '../animations/splashscreen_animation.dart';

// ---- MAJOR ---
// Global Toast Management System
class RootifyToast {
  // --- Fields
  static OverlayEntry? _currentEntry;

  // --- Sub
  // Primary Show Method
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Detail: Dismiss existing entry if active to avoid stacking
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);

    // Detail: Create and insert fresh entry
    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        isError: isError,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }

  // --- Sub
  // Convenience Presets
  static void success(BuildContext context, String message) =>
      show(context, message, icon: Icons.check_circle);

  static void error(BuildContext context, String message) =>
      show(context, message, icon: Icons.error, isError: true);

  static void info(BuildContext context, String message) =>
      show(context, message, icon: Icons.info);

  static void warning(BuildContext context, String message) =>
      show(context, message, icon: Icons.warning_amber);

  // --- Sub
  // Persistent Loading Toast
  static VoidCallback showLoading(BuildContext context, String message) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _LoadingToastWidget(message: message),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    return () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    };
  }
}

// ---- MAJOR ---
// Legacy Wrapper for Top Toasting
class TopToast {
  static void show(BuildContext context, String message,
      {bool isError = false}) {
    RootifyToast.show(context, message, isError: isError);
  }
}

// ---- MAJOR ---
// Internal Standard Toast Implementation
class _ToastWidget extends ConsumerWidget {
  final String message;
  final IconData? icon;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.onDismiss,
    required this.duration,
    this.icon,
    this.isError = false,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme & Layout Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Detail: Standard glass morphology calculation
    final double topMargin = MediaQuery.of(context).padding.top + 70;
    final glassColor = colorScheme.surfaceContainer;
    final textColor = colorScheme.onSurface;
    final accentColor = isError ? colorScheme.error : colorScheme.primary;
    final borderColor = colorScheme.outline.withValues(alpha: 0.4);

    // --- Sub
    // Visual Content Assembly
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 14),
              ],
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail: Duration indicator progress bar
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: duration, color: accentColor.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );

    // --- Sub
    // Final Overlay Position & Mask
    return Positioned(
      top: topMargin,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          // Detail: Tablet Constraint - Limit max width
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: RootifyBlur(
                category: BlurCategory.toast,
                color: glassColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(28),
                child: content,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .addEffects(ToastAnimations.entry())
        .then(delay: duration)
        .addEffects(ToastAnimations.exit())
        .callback(callback: (_) => onDismiss());
  }
}

// ---- MAJOR ---
// Persistent Loading Indicator Variant
class _LoadingToastWidget extends StatelessWidget {
  final String message;

  const _LoadingToastWidget({required this.message});

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Orientation Setup
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double topMargin = MediaQuery.of(context).padding.top + 70;
    final glassColor = colorScheme.surfaceContainer;
    final textColor = colorScheme.onSurface;
    final borderColor = colorScheme.outline.withValues(alpha: 0.4);

    // --- Sub
    // Content Layout
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Detail: Scaled logo path animation as loader
          SizedBox(
            width: 24,
            height: 24,
            child: SplashScreenAnimation.drawPathAnimation(
              path:
                  SplashScreenAnimation.getOfficialLogoPath(const Size(24, 24)),
              color: colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );

    // --- Sub
    // Final Overlay Wrap
    return Positioned(
      top: topMargin,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: RootifyBlur(
                category: BlurCategory.toast,
                color: glassColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(28),
                child: content,
              ),
            ),
          ),
        ),
      ),
    ).animate().addEffects(ToastAnimations.entry());
  }
}
