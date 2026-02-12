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
import 'about_widgets.dart';

// ---- MAJOR ---
// Ecosystem & Support Section for About App
// --- EcosystemSection
class EcosystemSection extends StatelessWidget {
  final VoidCallback onSourceCodeTap;
  final VoidCallback onSupportTap;

  const EcosystemSection({
    super.key,
    required this.onSourceCodeTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sub
        // Header
        const AboutSectionHeader(title: "Ecosystem & Support"),
        // --- Sub
        // Link Tiles
        _InfoLinkTile(
          icon: LucideIcons.github,
          title: "Source Code",
          subtitle: "View on GitHub",
          onTap: onSourceCodeTap,
        ),
        _InfoLinkTile(
          icon: LucideIcons.users,
          title: "Telegram Community",
          subtitle: "Get support & updates",
          onTap: onSupportTap,
        ),
      ],
    );
  }
}

// Supporting widget for navigation links in Ecosystem/Legal sections
// --- InfoLinkTile
class _InfoLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InfoLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AboutContactCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      isClickable: true,
      onTap: onTap,
    );
  }
}
