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
import '../../theme/theme_provider.dart';
import '../../theme/rootify_background_provider.dart';
import '../../widgets/cards.dart';
import '../statusbar/sb_themesettings.dart';
import 'banner_picker.dart';
import '../../animations/master_transition.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

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
        body: RootifySubBackground(
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _DelayedPopupWarning(
                          key: ValueKey(themeState.visualStyle),
                          isVisible:
                              themeState.visualStyle == AppVisualStyle.aurora,
                          child: _buildAuroraWarning(context, themeState),
                        ),
                        _buildSectionHeader(context, "System Theme"),
                        _buildThemeModeSelector(context, ref, themeState),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, "Color Scheme"),
                        _buildColorPicker(context, ref, themeState),
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
              Positioned(
                top: topPadding + 10,
                left: 0,
                right: 0,
                child: const ThemeSettingsStatusBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Methods
  void _handleThemeChange(
      BuildContext context, WidgetRef ref, AppThemeMode mode) {
    if (ref.read(themeProvider).mode == mode) {
      return;
    }

    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, 0);

    MasterTransition.of(context).changeTheme(
      position: center,
      onThemeChanged: () {
        ref.read(themeProvider.notifier).setMode(mode);
      },
    );
  }

  void _handleColorChange(BuildContext context, WidgetRef ref, Color color) {
    if (ref.read(themeProvider).accentColor == color &&
        !ref.read(themeProvider).useMonet) {
      return;
    }
    ref.read(themeProvider.notifier).setAccentColor(color);
  }

  void _handleMonetToggle(BuildContext context, WidgetRef ref, bool value) {
    if (ref.read(themeProvider).useMonet == value) {
      return;
    }
    ref.read(themeProvider.notifier).setUseMonet(value);
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
            onTap: () => _handleThemeChange(context, ref, AppThemeMode.system),
          ),
          const Divider(height: 1, indent: 48),
          _buildThemeOption(
            context,
            title: "Factory Default",
            subtitle: "Original Rootify appearance",
            icon: LucideIcons.layoutTemplate,
            isSelected: state.mode == AppThemeMode.appDefault,
            onTap: () =>
                _handleThemeChange(context, ref, AppThemeMode.appDefault),
          ),
          const Divider(height: 1, indent: 48),
          _buildThemeOption(
            context,
            title: "Core Dark",
            subtitle: "Pure Rootify slate experience",
            icon: LucideIcons.moon,
            isSelected: state.mode == AppThemeMode.dark,
            onTap: () => _handleThemeChange(context, ref, AppThemeMode.dark),
          ),
          const Divider(height: 1, indent: 48),
          _buildThemeOption(
            context,
            title: "Pristine Light",
            subtitle: "Clean and high-contrast clean UI",
            icon: LucideIcons.sun,
            isSelected: state.mode == AppThemeMode.light,
            onTap: () => _handleThemeChange(context, ref, AppThemeMode.light),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Background Style Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Visual Identity",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                SegmentedButton<AppVisualStyle>(
                  segments: const [
                    ButtonSegment(
                      value: AppVisualStyle.aurora,
                      label: Text("Aurora"),
                      icon: Icon(LucideIcons.zap),
                    ),
                    ButtonSegment(
                      value: AppVisualStyle.material,
                      label: Text("Material 3"),
                      icon: Icon(LucideIcons.palette),
                    ),
                  ],
                  selected: {state.visualStyle},
                  onSelectionChanged: (Set<AppVisualStyle> newSelection) async {
                    final newStyle = newSelection.first;
                    if (newStyle == state.visualStyle) {
                      return;
                    }

                    // Sequential Transition Logic:
                    // If leaving Aurora, hide the warning card FIRST before capturing the screenshot.
                    if (state.visualStyle == AppVisualStyle.aurora) {
                      ref
                          .read(themeProvider.notifier)
                          .setAuroraWarningDismissed(true);
                      // Wait for the Scale/Fade out animation to complete
                      await Future.delayed(const Duration(milliseconds: 400));
                    }

                    if (!context.mounted) return;

                    MasterTransition.of(context).changeStyle(
                      targetStyle: newStyle,
                      onStyleChanged: () {
                        ref
                            .read(themeProvider.notifier)
                            .setVisualStyle(newStyle);
                        // Reset dismissal state for next time
                        ref
                            .read(themeProvider.notifier)
                            .setAuroraWarningDismissed(false);
                      },
                    );
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: WidgetStateProperty.all(BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    )),
                  ),
                ),
              ],
            ),
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
          const SizedBox(width: 16),
          const Expanded(
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
          const Icon(LucideIcons.chevronRight, size: 16),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
      BuildContext context, WidgetRef ref, ThemeState state) {
    return RootifyCard(
      title: "Accent Color",
      subtitle: "Personalize system colors and branding",
      icon: LucideIcons.palette,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Material You (Monet)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text("Use wallpaper-based dynamic colors",
                style: TextStyle(fontSize: 12)),
            value: state.useMonet,
            onChanged: (val) => _handleMonetToggle(context, ref, val),
            activeTrackColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            inactiveThumbColor: Theme.of(context).colorScheme.outline,
            contentPadding: EdgeInsets.zero,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: _PaletteData.categories.entries.map((e) {
                  return _ColorPickerRow(
                    title: e.key,
                    colors: e.value,
                  );
                }).toList(),
              ),
            ),
            crossFadeState: state.useMonet
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOutQuart,
          ),
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
                _buildExperimentalBadge(theme),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text("Glassmorphism Effects",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Enable blur backgrounds on components",
                      style: TextStyle(fontSize: 12)),
                  value: state.enableBlurCards,
                  onChanged: state.visualStyle == AppVisualStyle.aurora
                      ? null
                      : (val) {
                          if (val && !state.isCardBlurWarningAccepted) {
                            _showBlurWarning(context, ref);
                          } else {
                            ref
                                .read(themeProvider.notifier)
                                .toggleBlurCards(val);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExperimentalBadge(theme),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text("Dock & Status Blur",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                      "Apply blur to system bars and dock area",
                      style: TextStyle(fontSize: 12)),
                  value: state.enableBlurDockStatus,
                  onChanged: state.visualStyle == AppVisualStyle.aurora
                      ? null
                      : (val) => ref
                          .read(themeProvider.notifier)
                          .toggleBlurDockStatus(val),
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

          // Sub-Card 3: Toast Notification
          RootifySubCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExperimentalBadge(theme),
                const SizedBox(height: 4),
                SwitchListTile(
                  title: const Text("Toast Notification Blur",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Soft background for system messages",
                      style: TextStyle(fontSize: 12)),
                  value: state.enableBlurToast,
                  onChanged: state.visualStyle == AppVisualStyle.aurora
                      ? null
                      : (val) =>
                          ref.read(themeProvider.notifier).toggleBlurToast(val),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Blur Intensity",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("Adjust the strength of the blur effect",
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
                  min: 0.0,
                  max: 30.0,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  thumbColor: theme.colorScheme.primary,
                  onChanged: state.visualStyle == AppVisualStyle.aurora
                      ? null
                      : (val) =>
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
                  enabled: state.visualStyle != AppVisualStyle.aurora,
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

  Widget _buildAuroraWarning(BuildContext context, ThemeState state) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey("aurora_warning"),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle,
              size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Performance Mode Active",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Blur effects are locked in Aurora mode to ensure fluid performance and protect your GPU.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onErrorContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentalBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
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

// --- MIGRATED ---
// Color Picker Components

class _ColorPickerRow extends ConsumerWidget {
  final String title;
  final List<Color> colors;

  const _ColorPickerRow({required this.title, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _ColorSwatch(color: colors[index]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ColorSwatch extends ConsumerWidget {
  final Color color;
  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
        themeProvider.select((s) => !s.useMonet && s.accentColor == color));

    return GestureDetector(
      onTap: () => ThemeSettingsPage()._handleColorChange(context, ref, color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2)
                ]
              : null,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: isSelected
            ? const Icon(LucideIcons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}

class _PaletteData {
  static const Map<String, List<Color>> categories = {
    "Soft (Nord)": [
      Color(0xFF3B82F6), // Blue
      Color(0xFF5E81AC), // Slate Blue
      Color(0xFF81A1C1), // Cornflower Blue
      Color(0xFF88C0D0), // Light Cyan
      Color(0xFF8FBCBB), // Teal
      Color(0xFFBF616A), // Red
      Color(0xFFD08770), // Coral
      Color(0xFFEBCB8B), // Gold
      Color(0xFFA3BE8C), // Sage Green
      Color(0xFFB48EAD), // Mauve
    ],
    "Vibrant": [
      Colors.redAccent, // #FF5252
      Colors.blueAccent, // #2979F0
      Colors.lightBlueAccent, // #40C4FF
      Colors.cyanAccent, // #00E5FF
      Colors.greenAccent, // #69F0AE
      Colors.limeAccent, // #00E676
      Colors.yellowAccent, // #FFFF00
      Colors.orangeAccent, // #FF6E40
      Colors.purpleAccent, // #E040FB
      Colors.pinkAccent, // #FF4081
    ],
    "Material": [
      Colors.blue, // Material Blue
      Colors.green, // Material Green
      Colors.red, // Material Red
      Colors.orange, // Material Orange
      Colors.purple, // Material Purple
      Colors.teal, // Material Teal
      Colors.indigo, // Material Indigo
      Colors.indigoAccent, // Material Indigo Accent
      Colors.brown, // Material Brown
      Colors.blueGrey, // Material Blue Grey
    ],
  };
}

class _DelayedPopupWarning extends ConsumerStatefulWidget {
  final bool isVisible;
  final Widget child;

  const _DelayedPopupWarning(
      {super.key, required this.isVisible, required this.child});

  @override
  ConsumerState<_DelayedPopupWarning> createState() =>
      _DelayedPopupWarningState();
}

class _DelayedPopupWarningState extends ConsumerState<_DelayedPopupWarning>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (widget.isVisible) {
      _startDelay();
    }
  }

  void _startDelay() async {
    // Increase delay to ensure it appears AFTER the 700ms horizontal wipe
    await Future.delayed(const Duration(milliseconds: 1950));
    if (mounted && widget.isVisible) {
      setState(() => _shouldShow = true);
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_DelayedPopupWarning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startDelay();
      } else {
        setState(() => _shouldShow = false);
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(themeProvider.select((s) => s.isAuroraWarningDismissed),
        (previous, next) {
      if (next && _shouldShow) {
        if (mounted) {
          setState(() => _shouldShow = false);
          _controller.reverse();
        }
      }
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _shouldShow
          ? ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: widget.child,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
