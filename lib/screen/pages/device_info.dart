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
import 'dart:io';
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---- LOCAL ---
import '../../shell/superuser.dart';
import '../../theme/theme_provider.dart';
import '../../theme/rootify_background_provider.dart';
import '../../services/vendor.dart';
import '../statusbar/sb_deviceinfo.dart';

// Info Widgets
import '../widgets/hardware.dart';
import '../widgets/os.dart';
import '../widgets/kernel.dart';
import '../widgets/processor.dart';
import '../widgets/graphics.dart';
import '../widgets/memory.dart';
import '../widgets/battery.dart';

// ---- MAJOR ---
// Device Technical Specifications & Branded Identity
class DeviceInfoPage extends ConsumerStatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  ConsumerState<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends ConsumerState<DeviceInfoPage> {
  // ---- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // --- Sub
    // Watch Hardware Data
    final infoAsync = ref.watch(vendorInfoProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RootifyMainBackground(
        child: Stack(
          children: [
            // --- Sub
            // 2. Main Scrolling Content
            infoAsync.when(
              data: (info) => CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Space
                  SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),

                  // Premium Brand Hero Section
                  SliverToBoxAdapter(child: _buildHeroBanner(context, info)),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Essential Specification Cards
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        HardwareSection(info: info),
                        OsSection(info: info),
                        KernelSection(info: info),
                        const ProcessorSection(),
                        const GraphicsSection(),
                        const MemorySection(),
                        const BatterySection(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  _ErrorState(error: err.toString(), theme: Theme.of(context)),
            ),

            // --- Sub
            // 3. Floating Status Bar
            Positioned(
              top: topPadding + 10,
              left: 0,
              right: 0,
              child: const DeviceInfoStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- HELPER BUILDERS ---

  Widget _buildHeroBanner(BuildContext context, VendorDetails info) {
    final themeState = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    DecorationImage? decorationImage;
    Widget? fallbackWidget;

    // --- Sub
    // 1. Resolve Banner Source
    switch (themeState.heroBannerType) {
      case HeroBannerType.dynamic:
        fallbackWidget = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.4),
                colorScheme.secondary.withValues(alpha: 0.3),
              ],
            ),
          ),
        );
        break;
      case HeroBannerType.asset:
        if (themeState.heroBannerPath != null) {
          decorationImage = DecorationImage(
            image: AssetImage(themeState.heroBannerPath!),
            fit: BoxFit.cover,
          );
        }
        break;
      case HeroBannerType.custom:
        if (themeState.heroBannerPath != null) {
          decorationImage = DecorationImage(
            image: FileImage(File(themeState.heroBannerPath!)),
            fit: BoxFit.cover,
          );
        }
        break;
    }

    // Final fallback if asset/file is missing
    if (decorationImage == null && fallbackWidget == null) {
      decorationImage = const DecorationImage(
        image: AssetImage('assets/banner/banner-1.jpg'),
        fit: BoxFit.cover,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: decorationImage,
      ),
      child: Stack(
        children: [
          if (fallbackWidget != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: fallbackWidget,
            ),
          // Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          // Positioned Root Status
          const Positioned(
            top: 20,
            right: 20,
            child: _RootStatusPill(),
          ),
          // Centered Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    info.model.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      info.manufacturer.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ---- SUPPORTING WIDGETS ---

class _RootStatusPill extends ConsumerWidget {
  const _RootStatusPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootStatusAsync = ref.watch(rootAccessProvider);

    return rootStatusAsync.when(
      data: (status) {
        final isGranted = status == RootStatus.granted;
        final color =
            isGranted ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isGranted ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                isGranted ? "ROOTED" : "UNROOTED",
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final ThemeData theme;
  const _ErrorState({required this.error, required this.theme});

  @override
  Widget build(BuildContext context) {
    // --- Layout: Error Theme
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, color: errorColor, size: 32),
            const SizedBox(height: 8),
            const Text("Access Failed",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 4),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
