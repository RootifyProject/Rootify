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

// ---- LOCAL ---
import '../theme/core/color.dart';

// ---- MAJOR ---
// Rootify Input Decoration System
class RootifyInputDecoration {
  // --- Sub
  // Dark Mode Decoration
  static InputDecoration dark({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: DarkColors.onSurface.withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: DarkColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: DarkColors.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: DarkColors.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: DarkColors.primaryBright,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: DarkColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // --- Sub
  // Light Mode Decoration
  static InputDecoration light({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: LightColors.onSurface.withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: LightColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: LightColors.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: LightColors.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LightColors.primaryBright,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LightColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // --- Sub
  // Adaptive Context-Aware Decoration
  static InputDecoration adaptive({
    required BuildContext context,
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffix: suffix,
      filled: true,
      fillColor: isDarkMode
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }

  // --- Sub
  // Legacy Theme Fallback
  static InputDecoration theme({
    required String hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
    );
  }
}
