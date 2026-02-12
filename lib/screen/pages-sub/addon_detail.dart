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
import 'package:flutter_animate/flutter_animate.dart';

// ---- LOCAL ---
import '../../providers/addons_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/toast.dart';
import 'details.dart';

// ---- MAJOR ---
// Addon Detailed Description Page
class AddonDetailPage extends ConsumerWidget {
  final dynamic config;
  final bool isRunning;
  final int? pid;
  final bool isProcessing;
  final bool isModuleMode;
  final VoidCallback onAction;
  final VoidCallback onLog;

  const AddonDetailPage({
    super.key,
    required this.config,
    required this.isRunning,
    this.pid,
    required this.isProcessing,
    required this.isModuleMode,
    required this.onAction,
    required this.onLog,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Theme & Context
    final theme = Theme.of(context);
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
                    // Detail: Primary Glow
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
                    // Detail: Secondary Glow
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.secondary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
                          begin: const Offset(-30, 30),
                          end: const Offset(30, -30),
                          duration: 10.seconds),
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
                // Detail: Premium Stretching Header
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor:
                          isDarkMode ? Colors.black26 : Colors.white54,
                      child: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Hero(
                            tag: "addon_icon_${config.id}",
                            child: Icon(
                              config.icon,
                              size: 80,
                              color: theme.primaryColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.surface
                                      .withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Detail: Information Density Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub Detail: Title & Version Pill
                        Text(
                          config.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                config.version,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Sub Detail: Status Dashboard Card
                        StatusCard(
                          isRunning: isRunning,
                          pid: pid,
                          isModuleMode: isModuleMode,
                          theme: theme,
                          isDarkMode: isDarkMode,
                          ref: ref,
                        ),

                        const SizedBox(height: 16),

                        // Sub Detail: Boot Persistence Setting
                        BootSettingCard(
                          config: config,
                          theme: theme,
                          isDarkMode: isDarkMode,
                          ref: ref,
                        ),

                        const SizedBox(height: 32),

                        // Sub Detail: Description Area
                        const SectionTitle(title: "ABOUT"),
                        const SizedBox(height: 12),
                        Text(
                          config.longDescription,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sub Detail: Feature Checklist
                        const SectionTitle(title: "FEATURES"),
                        const SizedBox(height: 16),
                        ...config.features
                            .map((f) => FeatureItem(feature: f, theme: theme)),

                        const SizedBox(height: 32),

                        // Sub Detail: Developer Branding/Credits
                        CreditCard(
                          author: config.author,
                          license: config.license,
                          theme: theme,
                          isDarkMode: isDarkMode,
                          ref: ref,
                          onLicenseTap: () => _showLicensePage(
                              context, config.name, config.licensePath),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- Sub
            // 3. Floating Bottom Performance Action Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.0),
                      theme.colorScheme.surface.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Detail: Contextual Log Access
                    if (isRunning && !isProcessing)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: OutlinedButton(
                            onPressed: onLog,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28)),
                              backgroundColor: theme
                                  .colorScheme.surfaceContainer
                                  .withValues(alpha: 0.5),
                            ),
                            child: Icon(LucideIcons.fileText,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    // Detail: Primary Service Controller
                    Expanded(
                      flex: 3,
                      child: AddonActionButton(
                        label: isRunning ? "STOP SERVICE" : "RUN SERVICE",
                        onPressed: isProcessing ? null : onAction,
                        isRunning: isRunning,
                        isProcessing: isProcessing,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers
  void _showLicensePage(BuildContext context, String name, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          title: "$name License",
          assetPath: path,
          icon: LucideIcons.scale,
        ),
      ),
    );
  }
}

// ---- SUPPORTING ---

// Service Runtime Status Display Card
class StatusCard extends StatelessWidget {
  final bool isRunning;
  final int? pid;
  final bool isModuleMode;
  final ThemeData theme;
  final bool isDarkMode;
  final WidgetRef ref;

  const StatusCard({
    super.key,
    required this.isRunning,
    this.pid,
    required this.isModuleMode,
    required this.theme,
    required this.isDarkMode,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Status Logic Context
    final color = isRunning ? const Color(0xFF10B981) : theme.hintColor;

    return RootifySubCard(
      child: Row(
        children: [
          // Detail: Status Icon Indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(
              isRunning ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Detail: Status Text Mapping
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRunning
                      ? (pid != null
                          ? "SERVICE RUNNING • PID: $pid"
                          : "SERVICE RUNNING")
                      : "SERVICE INACTIVE",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isModuleMode
                      ? "Integrated via Magisk Payload"
                      : "Running as standalone process",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Module Boot Survival Toggle Card
class BootSettingCard extends ConsumerWidget {
  final dynamic config;
  final ThemeData theme;
  final bool isDarkMode;
  final WidgetRef ref;

  const BootSettingCard({
    super.key,
    required this.config,
    required this.theme,
    required this.isDarkMode,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Sub
    // Boot Preference State Context
    final moduleState = ref.watch(moduleStateProvider);
    final isBootEnabled = config.id == "laya-kernel-tuner"
        ? moduleState.isKTBootEnabled
        : moduleState.isBMBootEnabled;

    return RootifySubCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Detail: Label & Icon
          Row(
            children: [
              Icon(
                LucideIcons.power,
                size: 14,
                color: isBootEnabled
                    ? theme.colorScheme.primary
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 10),
              Text(
                "Apply on Boot",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          // Detail: Toggle Management
          Switch(
            value: isBootEnabled,
            onChanged: (val) async {
              try {
                if (config.id == "laya-kernel-tuner") {
                  await ref
                      .read(moduleStateProvider.notifier)
                      .toggleKTBoot(val);
                } else {
                  await ref
                      .read(moduleStateProvider.notifier)
                      .toggleBMBoot(val);
                }
                if (context.mounted) {
                  RootifyToast.success(context,
                      "Apply on Boot ${val ? 'enabled' : 'disabled'} for ${config.name}");
                }
              } catch (e) {
                if (context.mounted) {
                  RootifyToast.error(
                      context, e.toString().replaceFirst('Exception: ', ''));
                }
              }
            },
            activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: theme.colorScheme.primary,
            inactiveTrackColor:
                theme.colorScheme.outline.withValues(alpha: 0.2),
            inactiveThumbColor: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

// Minimalistic Section Label
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// Individual Feature Line Item
class FeatureItem extends StatelessWidget {
  final String feature;
  final ThemeData theme;
  const FeatureItem({super.key, required this.feature, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            feature,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Author Information & Legal Card
class CreditCard extends StatelessWidget {
  final String author;
  final String license;
  final ThemeData theme;
  final bool isDarkMode;
  final WidgetRef ref;
  final VoidCallback onLicenseTap;

  const CreditCard({
    super.key,
    required this.author,
    required this.license,
    required this.theme,
    required this.isDarkMode,
    required this.ref,
    required this.onLicenseTap,
  });

  @override
  Widget build(BuildContext context) {
    return RootifySubCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Detail: Author Avatar Icon
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(LucideIcons.users,
                size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          // Detail: Metadata Labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DEVELOPED BY",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Detail: License Navigation
          TextButton(
            onPressed: onLicenseTap,
            child: Text(
              license,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized Service Execution Button
class AddonActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isRunning;
  final bool isProcessing;
  final ThemeData theme;

  const AddonActionButton({
    super.key,
    required this.label,
    this.onPressed,
    required this.isRunning,
    required this.isProcessing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Button Logic Context
    final isEnabled = onPressed != null;
    final color1 =
        isRunning ? const Color(0xFFEF4444) : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color1,
          side: BorderSide(
            color:
                isEnabled ? color1 : theme.disabledColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: color1),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
