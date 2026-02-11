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

// ---- MAJOR ---
// Light Theme Specification
class AppLightTheme {
  // --- Sub
  // Master Theme Data Constructor
  static ThemeData theme(Color accentColor, {ColorScheme? colorScheme}) {
    // Comment: Derived scheme from seed color (Monet or Manual)
    final effectiveColorScheme = colorScheme ??
        ColorScheme.fromSeed(
            seedColor: accentColor, brightness: Brightness.light);

    final typography =
        Typography.material2021(platform: TargetPlatform.android);
    final textTheme = typography.black.apply(fontFamily: 'Inter');

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: effectiveColorScheme.primary,
      scaffoldBackgroundColor: effectiveColorScheme.surface,
      cardColor: effectiveColorScheme.surfaceContainerLow,
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: effectiveColorScheme,
      textTheme: textTheme,

      // --- Sub
      // Surface & Hierarchy Styling
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: effectiveColorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: effectiveColorScheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveColorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 24,
      ),
      cardTheme: CardThemeData(
        color: effectiveColorScheme.surfaceContainerLow,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: effectiveColorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // --- Sub
      // Interactive Component Styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: effectiveColorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: effectiveColorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: effectiveColorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: effectiveColorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColorScheme.primary,
          foregroundColor: effectiveColorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: effectiveColorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
            color: effectiveColorScheme.onInverseSurface,
            fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
