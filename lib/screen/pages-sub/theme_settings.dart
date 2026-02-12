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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../theme/theme_provider.dart';
import '../../widgets/cards.dart';
import '../statusbar/sb_themesettings.dart';
import 'banner_picker.dart';

// ---- MAJOR ---
// Advanced Visual Identity & Theme Configuration Page
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // --- Sub
            // 1. Mirrored Dynamic Mesh Background
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -120,
                      left: -120,
                      child: Container(
                        width: 450,
                        height: 450,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.15),
                              colorScheme.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(30, -30),
                          end: const Offset(-30, 30),
                          duration: 12.seconds),
                    ),
                  ],
                ),
              ),
            ),

            // --- Sub
            // 2. Main Scrolling Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Detail: Functional Header
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 80)),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionHeader(context, "System Theme"),
                      _buildThemeModeSelector(context, ref, themeState),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Branding"),
                      _buildBannerPickerTile(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Visual Effects"),
                      _buildBlurControls(context, ref, themeState),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),

            // --- Sub
            // Floating Status Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: const ThemeSettingsStatusBar(),
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
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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

  Widget _buildThemeModeSelector(
      BuildContext context, WidgetRef ref, ThemeState state) {
    return RootifyCard(
      child: Column(
        children: [
          _buildThemeOption(
            context,
            title: "Follow System",
            subtitle: "Sync with device lighting mode",
            icon: LucideIcons.monitor,
            isSelected: state.mode == AppThemeMode.system,
            onTap: () =>
                ref.read(themeProvider.notifier).setMode(AppThemeMode.system),
          ),
          const Divider(height: 1, indent: 48),
          _buildThemeOption(
            context,
            title: "Core Dark",
            subtitle: "Pure Rootify slate experience",
            icon: LucideIcons.moon,
            isSelected: state.mode == AppThemeMode.dark,
            onTap: () =>
                ref.read(themeProvider.notifier).setMode(AppThemeMode.dark),
          ),
          const Divider(height: 1, indent: 48),
          _buildThemeOption(
            context,
            title: "Pristine Light",
            subtitle: "Clean and high-contrast clean UI",
            icon: LucideIcons.sun,
            isSelected: state.mode == AppThemeMode.light,
            onTap: () =>
                ref.read(themeProvider.notifier).setMode(AppThemeMode.light),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("Material You (Monet)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text("Use wallpaper-based dynamic colors",
                style: TextStyle(fontSize: 12)),
            value: state.useMonet,
            onChanged: (val) =>
                ref.read(themeProvider.notifier).setUseMonet(val),
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            inactiveThumbColor: Theme.of(context).colorScheme.outline,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: isSelected ? theme.colorScheme.primary : theme.hintColor),
      title: Text(title,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(LucideIcons.checkCircle,
              color: theme.colorScheme.primary, size: 20)
          : null,
    );
  }

  Widget _buildBannerPickerTile(BuildContext context) {
    return RootifyCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const BannerPickerPage())),
      child: Row(
        children: [
          Icon(LucideIcons.image,
              size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("App Hero Banner",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Change the header image on Device Info page",
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16),
        ],
      ),
    );
  }

  Widget _buildBlurControls(
      BuildContext context, WidgetRef ref, ThemeState state) {
    final theme = Theme.of(context);

    if (!state.isAdvancedBlurUnlocked) {
      return RootifyCard(
        title: "Visual Effects",
        subtitle: "Advanced system appearance settings",
        icon: LucideIcons.layers,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                LucideIcons.lock,
                size: 32,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "FEATURE LOCKED",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This visual customization suite is a hidden premium feature.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RootifyCard(
      title: "Visual Effects",
      subtitle: "Customize system transparency and blur",
      icon: LucideIcons.layers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Card 1: Glassmorphism
          RootifySubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    "EXPERIMENTAL",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text("Glassmorphism Effects",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  subtitle: const Text("Enable blur backgrounds on components",
                      style: TextStyle(fontSize: 12)),
                  value: state.enableBlurCards,
                  onChanged: (val) {
                    if (val && !state.isCardBlurWarningAccepted) {
                      _showBlurWarning(context, ref);
                    } else {
                      ref.read(themeProvider.notifier).toggleBlurCards(val);
                    }
                  },
                  activeTrackColor:
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                  activeThumbColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.outline.withValues(alpha: 0.2),
                  inactiveThumbColor: theme.colorScheme.outline,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sub-Card 2: Dock & Status
          RootifySubCard(
            child: SwitchListTile(
              title: const Text("Dock & Status Blur",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Apply blur to system bars and dock area",
                  style: TextStyle(fontSize: 12)),
              value: state.enableBlurDockStatus,
              onChanged: (val) =>
                  ref.read(themeProvider.notifier).toggleBlurDockStatus(val),
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              activeThumbColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          // Sub-Card 3: Toast Notification
          RootifySubCard(
            child: SwitchListTile(
              title: const Text("Toast Notification Blur",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Soft background for system messages",
                  style: TextStyle(fontSize: 12)),
              value: state.enableBlurToast,
              onChanged: (val) =>
                  ref.read(themeProvider.notifier).toggleBlurToast(val),
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.5),
              activeThumbColor: theme.colorScheme.primary,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Sub-Card 4: Intensity
          RootifySubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Blur Intensity",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text("Adjust the strength of the blur effect",
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${state.blurSigma.toStringAsFixed(1)}px",
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                Slider(
                  value: state.blurSigma,
                  min: 1.0,
                  max: 15.0,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  thumbColor: theme.colorScheme.primary,
                  onChanged: (val) =>
                      ref.read(themeProvider.notifier).setBlurSigma(val),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle,
                        size: 10,
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Recommended: 2.5 - 4.5. Higher values are CPU intensive.",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sub-Card 5: Engine
          RootifySubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Blur Engine",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("Choose the rendering algorithm",
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                DropdownMenu<AppBlurStyle>(
                  initialSelection: state.blurStyle,
                  expandedInsets: EdgeInsets.zero,
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerLowest),
                    surfaceTintColor:
                        WidgetStateProperty.all(theme.colorScheme.surface),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  dropdownMenuEntries: AppBlurStyle.values.map((style) {
                    final isSelected = style == state.blurStyle;
                    return DropdownMenuEntry(
                      value: style,
                      label: style.name.toUpperCase(),
                      labelWidget: Text(
                        style.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (val) {
                    if (val != null) {
                      ref.read(themeProvider.notifier).setBlurStyle(val);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBlurWarning(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Performance Notice"),
        content: const Text(
            "Ultra-blur effects can be CPU intensive on older devices. If you experience lag, please reduce blur intensity in advanced settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(themeProvider.notifier).acceptCardBlurWarning();
              ref.read(themeProvider.notifier).toggleBlurCards(true);
              Navigator.pop(context);
            },
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }
}
