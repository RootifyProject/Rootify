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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../effects/rootify_blur.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/toast.dart';

// ---- MAJOR ---
// Layout Constants
const double _kOverlayRadius = 28.0;
const double _kItemRadius = 14.0;
const double _kPadding = 24.0;
const double _kSectionSpacing = 28.0;

// ---- MAJOR ---
// Theme Settings Overlay Component
class ThemeSettingsOverlay extends ConsumerStatefulWidget {
  const ThemeSettingsOverlay({super.key});

  @override
  ConsumerState<ThemeSettingsOverlay> createState() =>
      _ThemeSettingsOverlayState();
}

// ---- MAJOR ---
// Theme Settings State Implementation
class _ThemeSettingsOverlayState extends ConsumerState<ThemeSettingsOverlay> {
  // --- Fields
  bool _isAdvancedExpanded = false;

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    // Detail
    // Adaptive width: capped at 500px for tablets/desktop, 90% for mobile
    final double containerWidth = screenWidth > 550 ? 500 : screenWidth * 0.9;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: _GlassSurface(
          width: containerWidth,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SettingsHeader(),

                const SizedBox(height: _kPadding),
                const _SectionTitle("Theme"),
                const SizedBox(height: 12),
                const _ThemeModeGrid(),

                const SizedBox(height: _kSectionSpacing),
                const _SectionTitle("Accent Color"),
                const SizedBox(height: 12),
                const _MonetToggle(),

                // Detail
                // Animated switch between monet and custom colors
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: _PaletteData.categories.entries.map((e) {
                        return _ColorPickerRow(
                          title: e.key,
                          colors: e.value,
                        );
                      }).toList(),
                    ),
                  ),
                  crossFadeState: themeState.useMonet
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOutQuart,
                ),

                // Advanced Toggle
                if (themeState.isAdvancedBlurUnlocked) ...[
                  const SizedBox(height: _kSectionSpacing),
                  Center(
                    child: TonalButton(
                      onPressed: () => setState(
                          () => _isAdvancedExpanded = !_isAdvancedExpanded),
                      icon: _isAdvancedExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      label: _isAdvancedExpanded
                          ? "Hide Advanced"
                          : "Advanced Blur Settings",
                    ),
                  ),

                  // Collapsible Section
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: const _AdvancedSettingsSection(),
                    crossFadeState: _isAdvancedExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeInOutQuart,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- MAJOR ---
// Core UI Elements

// --- Sub
// Glass Surface Wrapper
class _GlassSurface extends ConsumerWidget {
  final Widget child;
  final double width;

  const _GlassSurface({required this.child, required this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return RootifyBlur(
      category: BlurCategory.overlay,
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(_kOverlayRadius),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
      child: RepaintBoundary(
        child: Container(
          width: width,
          padding: const EdgeInsets.all(_kPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(_kOverlayRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Sub
// Header with Title and Close Action
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Appearance",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "Customize your experience",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            shape: const CircleBorder(),
          ),
          icon: const Icon(LucideIcons.x, size: 20),
        ),
      ],
    );
  }
}

// --- Sub
// Section Divider with Label
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

// ---- MAJOR ---
// Theme Mode Selection

// --- Sub
// Grid of Theme Options
class _ThemeModeGrid extends StatelessWidget {
  const _ThemeModeGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
                child: _ModeCard(label: "System", mode: AppThemeMode.system)),
            SizedBox(width: 8),
            Expanded(
                child:
                    _ModeCard(label: "Default", mode: AppThemeMode.appDefault)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(
                child: _ModeCard(label: "Light", mode: AppThemeMode.light)),
            SizedBox(width: 8),
            Expanded(child: _ModeCard(label: "Dark", mode: AppThemeMode.dark)),
          ],
        ),
      ],
    );
  }
}

// --- Sub
// Individual Mode Selection Card
class _ModeCard extends ConsumerWidget {
  final String label;
  final AppThemeMode mode;

  const _ModeCard({required this.label, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isSelected = themeState.mode == mode;
    final activeColor = theme.colorScheme.primary;

    return InkWell(
      onTap: () => ref.read(themeProvider.notifier).setMode(mode),
      borderRadius: BorderRadius.circular(_kItemRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(_kItemRadius),
          border: Border.all(
            color: isSelected
                ? activeColor
                : theme.colorScheme.outline.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(mode),
              size: 18,
              color:
                  isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? activeColor : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => LucideIcons.smartphone,
        AppThemeMode.appDefault => LucideIcons.layoutTemplate,
        AppThemeMode.light => LucideIcons.sun,
        AppThemeMode.dark => LucideIcons.moon,
      };
}

// ---- MAJOR ---
// Color Customization

// --- Sub
// Toggle for System Monet Dynamic Colors
class _MonetToggle extends ConsumerWidget {
  const _MonetToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isMonet = themeState.useMonet;
    final activeColor = theme.colorScheme.primary;

    return InkWell(
      onTap: () => ref.read(themeProvider.notifier).setUseMonet(!isMonet),
      borderRadius: BorderRadius.circular(_kItemRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMonet
              ? activeColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(_kItemRadius),
          border: Border.all(
            color: isMonet
                ? activeColor
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: isMonet ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMonet
                    ? activeColor
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.palette,
                size: 16,
                color: isMonet
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dynamic Colors",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "Sync with system wallpaper",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isMonet,
              onChanged: (val) =>
                  ref.read(themeProvider.notifier).setUseMonet(val),
              activeTrackColor: activeColor.withValues(alpha: 0.5),
              activeThumbColor: activeColor,
              inactiveTrackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.2),
              inactiveThumbColor: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Sub
// Horizontal List of Color Swatches
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
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- Sub
// Individual Color Option
class _ColorSwatch extends ConsumerWidget {
  final Color color;
  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isSelected = !themeState.useMonet && themeState.accentColor == color;

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setAccentColor(color),
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

// ---- MAJOR ---
// Advanced Blur Settings (Collapsible)

// --- Sub
// Section Content for Advanced Blur
class _AdvancedSettingsSection extends StatelessWidget {
  const _AdvancedSettingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(height: 24),
        Divider(),
        SizedBox(height: 24),
        _SectionTitle("Blur Engine"),
        SizedBox(height: 12),
        _BlurStyleSelector(),
        SizedBox(height: 24),
        _SectionTitle("Targets"),
        SizedBox(height: 8),
        _BlurTargetsList(),
        SizedBox(height: 24),
        _BlurIntensitySlider(),
      ],
    );
  }
}

// --- Sub
// Dropdown to Select Blur Algorithm
class _BlurStyleSelector extends ConsumerWidget {
  const _BlurStyleSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_kItemRadius),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppBlurStyle>(
          value: themeState.blurStyle,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 18),
          dropdownColor: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_kItemRadius),
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          items: AppBlurStyle.values.map((style) {
            return DropdownMenuItem(
              value: style,
              child: Row(
                children: [
                  const Icon(LucideIcons.waves, size: 16),
                  const SizedBox(width: 12),
                  Text(style.name.toUpperCase()),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) ref.read(themeProvider.notifier).setBlurStyle(val);
          },
        ),
      ),
    );
  }
}

// --- Sub
// List of Toggleable UI Components for Blur
class _BlurTargetsList extends ConsumerWidget {
  const _BlurTargetsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Column(
      children: [
        _SettingsSwitch(
          label: "Card Surfaces",
          value: themeState.enableBlurCards,
          onChanged: (val) {
            if (val && !themeState.isCardBlurWarningAccepted) {
              // Show Warning Dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, color: Colors.orange),
                      SizedBox(width: 8),
                      Text("Performance Warning"),
                    ],
                  ),
                  content: const Text(
                      "Enabling Card Blur is a heavy feature. It may cause lag, increased battery drain, or heating on some devices.\n\nDo you want to proceed?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("DENY"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        notifier.acceptCardBlurWarning();
                        notifier.toggleBlurCards(true);
                        Navigator.pop(context);
                        RootifyToast.success(context, "Card Blur Enabled! ❄️");
                      },
                      child: const Text("ACCEPT"),
                    ),
                  ],
                ),
              );
            } else {
              notifier.toggleBlurCards(val);
            }
          },
        ),
        _SettingsSwitch(
          label: "Toast Messages",
          value: themeState.enableBlurToast,
          onChanged: notifier.toggleBlurToast,
        ),
        _SettingsSwitch(
          label: "Dock & Status Bar",
          value: themeState.enableBlurDockStatus,
          onChanged: notifier.toggleBlurDockStatus,
        ),
      ],
    );
  }
}

// --- Sub
// Shared Switch UI for Settings
class _SettingsSwitch extends ConsumerWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: themeState.enableBlurCards
            ? (isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.2))
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: theme.colorScheme.primary,
              activeThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sub
// Slider for Global Blur Intensity
class _BlurIntensitySlider extends ConsumerWidget {
  const _BlurIntensitySlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Intensity",
                style: TextStyle(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${themeState.blurSigma.toStringAsFixed(1)}px",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: themeState.blurSigma,
            min: 0.0,
            max: 30.0,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) =>
                ref.read(themeProvider.notifier).setBlurSigma(value),
          ),
        ),
      ],
    );
  }
}

// ---- MAJOR ---
// Static Theme Data
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
