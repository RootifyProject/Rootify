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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../animations/statusbar_animation.dart';
import '../../shell/superuser.dart';
import '../../effects/rootify_blur.dart';
import '../../theme/theme_provider.dart';
import '../../services/battery.dart';
import '../../animations/master_transition.dart';

// ---- MAJOR ---
// Primary System Status Bar Implementation
class SystemStatusBar extends ConsumerWidget {
  final String title;
  final Widget? customTitle;
  final bool showBackButton;
  final bool showRootStatus;
  final bool showThemeButton;
  final VoidCallback? onBack;

  const SystemStatusBar({
    required this.title,
    this.customTitle,
    this.showBackButton = false,
    this.showRootStatus = false,
    this.showThemeButton = false,
    this.onBack,
    super.key,
  });

  // --- UI Builder
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Configuration
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final rootStatusAsync = ref.watch(rootAccessProvider);
    final batteryAsync = ref.watch(batteryStreamProvider);

    // --- Sub
    // Glassmorphic Surface Container
    Widget glassContainer({required Widget child, EdgeInsets? padding}) {
      final themeState = ref.watch(themeProvider);
      final blurEnabled = themeState.enableBlurDockStatus;

      final glassColor = blurEnabled
          ? (isDarkMode
              ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.95))
          : (isDarkMode
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLow);

      return RootifyBlur(
        category: BlurCategory.dock,
        color: glassColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: themeState.visualStyle == AppVisualStyle.aurora
                ? colorScheme.primary.withValues(alpha: 0.15)
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1.5),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      );
    }

    // --- Sub
    // Root Permission Indicator
    Widget rootIndicator(RootStatus status) {
      final isGranted = status == RootStatus.granted;
      final statusColor = isGranted ? colorScheme.primary : colorScheme.error;
      final label = isGranted ? 'Root: OK' : 'No Root';

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.2)),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.5, 1.5),
                      duration: 1.5.seconds,
                      curve: Curves.easeOut)
                  .fadeOut(),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      );
    }

    // --- Sub
    // Real-time Power Status
    Widget batteryWidget(BatterySnapshot battery) {
      final isCharging = battery.status.isCharging;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${battery.temp.celsius.toStringAsFixed(0)}°',
              style: TextStyle(color: theme.hintColor, fontSize: 10)),
          const SizedBox(width: 6),
          Text('${battery.capacity.percentage}%',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 4),
          Icon(isCharging ? LucideIcons.batteryCharging : LucideIcons.battery,
              size: 14,
              color: isCharging ? colorScheme.primary : colorScheme.tertiary),
        ],
      );
    }

    // ---- COMPONENT ASSEMBLY ----
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Sub
            // Back Action Segment
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: BouncingButton(
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    child: glassContainer(
                      padding: EdgeInsets.zero,
                      child: const Center(
                          child: Icon(LucideIcons.chevronLeft, size: 20)),
                    ),
                  ),
                ),
              ),

            // --- Sub
            // Main Informational Glass
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 52),
                child: glassContainer(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Detail: Page Context / Primary Metric
                      Flexible(
                        child: customTitle ??
                            Text(title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 12)),
                      ),

                      // Detail: Static Visual Separator
                      Container(
                          width: 1.5,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: theme.dividerColor),

                      // Detail: System Streams
                      if (showRootStatus) ...[
                        rootStatusAsync.when(
                          data: rootIndicator,
                          loading: () => const SizedBox(width: 10),
                          error: (_, __) => const Icon(
                              LucideIcons.alertTriangle,
                              size: 14,
                              color: Colors.orange),
                        ),
                        Container(
                            width: 1.5,
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: theme.dividerColor),
                      ],

                      batteryAsync.when(
                        data: batteryWidget,
                        loading: () => const SizedBox(width: 10),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Sub
            // Theme Customization Toggle
            if (showThemeButton) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                width: 40,
                child: Builder(builder: (context) {
                  return BouncingButton(
                    onTap: () {
                      HapticFeedback.mediumImpact();

                      // Calculate button center for circular reveal
                      final renderBox =
                          context.findRenderObject() as RenderBox?;
                      final offset =
                          renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
                      final size = renderBox?.size ?? Size.zero;
                      final center =
                          offset + Offset(size.width / 2, size.height / 2);

                      // Trigger global transition
                      MasterTransition.of(context).changeTheme(
                        position: center,
                        onThemeChanged: () {
                          final newMode = isDarkMode
                              ? AppThemeMode.light
                              : AppThemeMode.dark;
                          ref.read(themeProvider.notifier).setMode(newMode);
                        },
                      );
                    },
                    child: glassContainer(
                      padding: EdgeInsets.zero,
                      child: Center(
                        child: ThemeButtonTransition(
                          child: Icon(
                            isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            key: ValueKey(isDarkMode),
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
