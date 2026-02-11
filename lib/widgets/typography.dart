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
// Standardized Typography System
class RootifyTypography {
  // --- Sub
  // Adaptive Context-Aware Scaling Styles

  static TextStyle adaptiveHeader(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w900,
      color: theme.colorScheme.onSurface,
      letterSpacing: -1.0,
      height: 1.1,
    );
  }

  static TextStyle adaptiveSubHeader(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );
  }

  static TextStyle adaptiveBody(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.1,
      height: 1.5,
    );
  }

  static TextStyle adaptiveCaption(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  static TextStyle adaptiveLink(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      decorationThickness: 2,
    );
  }

  // --- Sub
  // Static Design System Tokens

  static const TextStyle darkHeader = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: DarkColors.onBackground,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle darkSubHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: DarkColors.onBackground,
    letterSpacing: -0.5,
  );

  static const TextStyle lightHeader = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: LightColors.onBackground,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle lightSubHeader = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: LightColors.onBackground,
    letterSpacing: -0.5,
  );

  // --- Sub
  // Legacy Component Aliases
  static const TextStyle header = darkHeader;
  static const TextStyle subHeader = darkSubHeader;
}
