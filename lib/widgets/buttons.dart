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

// ---- MAJOR ---
// High-visibility Primary Action Button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Configuration
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        splashFactory: InkSparkle.splashFactory,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Balanced Prominence Tonal Button
class TonalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const TonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Configuration
    final theme = Theme.of(context);

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        splashFactory: InkSparkle.splashFactory,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
    );
  }
}

// ---- MAJOR ---
// Low-prominence Outlined Action Button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Configuration
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        splashFactory: InkSparkle.splashFactory,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
    );
  }
}
