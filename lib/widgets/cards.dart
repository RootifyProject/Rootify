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
import '../effects/rootify_blur.dart';
import '../theme/theme_provider.dart';

// ---- MAJOR ---
// Primary Section Card
class RootifyCard extends ConsumerWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const RootifyCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.padding,
    this.margin,
    this.onTap,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme & Layout Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final isAurora = themeState.visualStyle == AppVisualStyle.aurora;

    // --- Sub
    // Header Construction Logic
    Widget? header;
    if (title != null) {
      header = Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      );
    }

    // --- Sub
    // Core Content Assembly
    Widget columnContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) header,
        // Detail: Apply manual padding override if provided
        padding != null ? Padding(padding: padding!, child: child) : child,
      ],
    );

    // --- Sub
    // Interaction Layer (InkWell)
    if (onTap != null) {
      columnContent = InkWell(
        onTap: onTap,
        splashFactory: InkSparkle.splashFactory,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: columnContent,
        ),
      );
    } else {
      columnContent = Padding(
        padding: const EdgeInsets.all(28),
        child: columnContent,
      );
    }

    // --- Sub
    // Responsive Layout Builder
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detail: Calculate dynamic horizontal margin for tablet optimization
        double dynamicHorizontalMargin = 12.0;

        if (margin == null && constraints.maxWidth > 600) {
          // Detail: Use 15% margin for wide screens to create a centered column
          dynamicHorizontalMargin = constraints.maxWidth * 0.15;
        }

        final effectiveMargin = margin ??
            EdgeInsets.symmetric(
              vertical: 12,
              horizontal: dynamicHorizontalMargin,
            );

        // Detail: Final Render with Style-Based Color Logic
        final blurEnabled = themeState.enableBlurCards;
        Color cardColor;

        if (isAurora) {
          if (blurEnabled) {
            cardColor = isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03);
          } else {
            // Solid Aurora fallback: Slightly tinted surface for "vibrant" feel
            cardColor = isDarkMode
                ? Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.12),
                    colorScheme.surface)
                : Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.surface);
          }
        } else {
          // Material 3 fallback: Standard tonal surfaces
          cardColor = isDarkMode
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLow;

          if (blurEnabled) {
            cardColor = cardColor.withValues(alpha: 0.8);
          }
        }

        return Padding(
          padding: effectiveMargin,
          child: RootifyBlur(
            category: BlurCategory.card,
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isAurora
                  ? colorScheme.primary
                      .withValues(alpha: isDarkMode ? 0.15 : 0.1)
                  : colorScheme.outlineVariant
                      .withValues(alpha: isDarkMode ? 0.2 : 0.4),
              width: isAurora ? 1.0 : 1.5,
            ),
            child: columnContent,
          ),
        );
      },
    );
  }
}

// ---- MAJOR ---
// Nested Group Item Card
class RootifySubCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  const RootifySubCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme & Container Setup
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final isAurora = themeState.visualStyle == AppVisualStyle.aurora;
    final blurEnabled = themeState.enableBlurCards;

    Color subCardColor;
    if (color != null) {
      subCardColor = color!;
    } else if (isAurora) {
      if (blurEnabled) {
        subCardColor = isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02);
      } else {
        // Solid Aurora fallback
        subCardColor = isDarkMode
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08),
                theme.colorScheme.surfaceContainer)
            : Color.alphaBlend(Colors.black.withValues(alpha: 0.04),
                theme.colorScheme.surfaceContainer);
      }
    } else {
      subCardColor = isDarkMode
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

      if (!blurEnabled) {
        subCardColor = subCardColor.withValues(alpha: 1.0);
      }
    }

    Widget content = RootifyBlur(
      category: BlurCategory.subcard,
      color: subCardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isAurora
            ? theme.colorScheme.primary
                .withValues(alpha: isDarkMode ? 0.15 : 0.1)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    // --- Sub
    // Tap Feedback Application
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: margin ?? EdgeInsets.zero,
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: content,
    );
  }
}

// ---- MAJOR ---
// Visual Icon Badge Widget
class RootifyIconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const RootifyIconBadge({super.key, required this.icon, this.color});

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Context Check
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: isDarkMode ? Colors.white10 : Colors.transparent),
      ),
      child: Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
    );
  }
}

// ---- MAJOR ---
// Key-Value Tag Component
class RootifyTagBadge extends StatelessWidget {
  final String label;
  final String value;

  const RootifyTagBadge({
    super.key,
    required this.label,
    required this.value,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme & Styling Config
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black26
            : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Detail: Label Text
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          // Detail: Value Text (Monospace)
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Monospace',
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
