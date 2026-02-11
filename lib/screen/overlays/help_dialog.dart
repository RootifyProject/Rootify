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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/cards.dart';

class HelpOverlay {
  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required String usage,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.helpCircle,
                  color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RootifySubCard(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DESCRIPTION",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text(description,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  const Text("USAGE / EXAMPLE",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      usage,
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
