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
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../widgets/cards.dart';

// ---- LAYOUT COMPONENTS ---

// Branded Section Label for About sections
// --- SectionHeader
class AboutSectionHeader extends StatelessWidget {
  final String title;

  const AboutSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// Stylized Contact/Member Row with optional role tags
// --- ContactCard
class AboutContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? userId;
  final dynamic role;
  final VoidCallback? onTap;
  final bool isClickable;

  const AboutContactCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.userId,
    this.role,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RootifyCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail: Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          // Detail: Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (role != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (role is List)
                        ...role.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final r = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(left: idx == 0 ? 0 : 8),
                            child: AboutRoleTag(role: r.toString()),
                          );
                        })
                      else
                        AboutRoleTag(role: role.toString()),
                    ],
                  ),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isClickable)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 12),
              child: Icon(
                LucideIcons.externalLink,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- SUPPORTING ELEMENTS ---

// Small Stylized Role Pill used in Contact Rows
// --- RoleTag
class AboutRoleTag extends StatelessWidget {
  final String role;

  const AboutRoleTag({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Theme Context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = _getIconForRole(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: colorScheme.secondary),
            const SizedBox(width: 4),
          ],
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers
  IconData? _getIconForRole(String role) {
    final r = role.toLowerCase();
    if (r.contains('tester')) return LucideIcons.bug;
    if (r.contains('teacher') || r.contains('master')) {
      return LucideIcons.graduationCap;
    }
    if (r.contains('inspiration')) return LucideIcons.zap;
    if (r.contains('motivation')) return LucideIcons.flame;
    if (r.contains('friend')) return LucideIcons.heart;
    if (r.contains('addon')) return LucideIcons.package;
    if (r.contains('artist')) return LucideIcons.palette;
    if (r.contains('code')) return LucideIcons.code2;
    return null;
  }
}

// ---- DATA MODELS ---

// Model representing a single credit entry from JSON
// --- CreditItem
class CreditItem {
  final String name;
  final String tgid;
  final String description;
  final String type;
  final dynamic descriptionType;

  CreditItem({
    required this.name,
    required this.tgid,
    required this.description,
    required this.type,
    required this.descriptionType,
  });

  factory CreditItem.fromJson(Map<String, dynamic> json) {
    return CreditItem(
      name: json['name'] as String,
      tgid: json['tgid'] as String,
      description: json['description'] as String,
      type: json['type'] as String? ?? 'credits',
      descriptionType: json['description_type'],
    );
  }
}
