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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../widgets/cards.dart';
import '../../theme/rootify_background_provider.dart';
import '../pages-sub/about_app.dart';
import '../pages-sub/appearance.dart';
import '../pages-sub/feedback_reports.dart';

// ---- MAJOR ---
// Global Application Settings & Technical Configuration
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RootifyMainBackground(
        child: CustomScrollView(
          key: const PageStorageKey('settings_page_scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader(context, "General"),
                  _buildSettingCard(
                    context,
                    title: "About App",
                    subtitle: "Version, developer, and legal information",
                    icon: LucideIcons.info,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AppInfoPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context,
                    title: "Feedback & Report Bugs",
                    subtitle: "Help us improve by sharing your thoughts",
                    icon: LucideIcons.messageSquare,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackReportsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, "Interface"),
                  _buildSettingCard(
                    context,
                    title: "Appearance",
                    subtitle: "Theme, colors, and visual effects",
                    icon: LucideIcons.palette,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSettingsPage(),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
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

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return RootifyCard(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}
