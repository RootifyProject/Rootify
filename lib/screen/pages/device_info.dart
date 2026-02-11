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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ---- LOCAL ---
import '../../providers/cpu_provider.dart';
import '../../services/vendor.dart';
import '../../services/battery.dart';
import '../../services/ramzram.dart';
import '../../services/gpu.dart';
import '../../shell/superuser.dart';
import '../../theme/theme_provider.dart';
import '../statusbar/sb_deviceinfo.dart';
import '../../widgets/cards.dart';

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
    // Theme & Context
    final colorScheme = Theme.of(context).colorScheme;

    // --- Sub
    // Watch Hardware Data
    final infoAsync = ref.watch(vendorInfoProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
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
                  // Primary Glow
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
                  // Secondary Glow
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
                      _buildHardwareSection(context, info),
                      _buildSoftwareSection(context, info),
                      _buildKernelSection(context, info),
                      _buildProcessorSection(context),
                      _buildGraphicsSection(context),
                      _buildMemorySection(context),
                      _buildBatterySection(context),
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

  Widget _buildHardwareSection(BuildContext context, VendorDetails info) {
    return RootifyCard(
      title: "Hardware",
      icon: LucideIcons.cog,
      child: Column(
        children: [
          _DetailTile(
              icon: LucideIcons.tag,
              label: "Model",
              value: info.model,
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.factory,
              label: "Manufacturer",
              value: info.manufacturer,
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.box,
              label: "Codename",
              value: info.codename,
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.cpu,
              label: "Platform",
              value: info.board,
              theme: Theme.of(context)),
        ],
      ),
    );
  }

  Widget _buildSoftwareSection(BuildContext context, VendorDetails info) {
    return RootifyCard(
      title: "Software",
      icon: LucideIcons.code2,
      child: Column(
        children: [
          _DetailTile(
              icon: LucideIcons.smartphone,
              label: "Android Version",
              value: info.androidVersion,
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.hash,
              label: "SDK Level",
              value: info.sdkLevel.toString(),
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.shieldCheck,
              label: "Security Patch",
              value: info.securityPatch,
              theme: Theme.of(context)),
        ],
      ),
    );
  }

  Widget _buildKernelSection(BuildContext context, VendorDetails info) {
    return RootifyCard(
      title: "Kernel",
      icon: LucideIcons.terminal,
      child: Column(
        children: [
          _DetailTile(
              icon: FontAwesomeIcons.linux,
              label: "Kernel Version",
              value: info.kernel.split('#').first.trim(),
              theme: Theme.of(context)),
          _DetailTile(
              icon: LucideIcons.cpu,
              label: "Architecture",
              value: info.arch,
              theme: Theme.of(context)),
        ],
      ),
    );
  }

  Widget _buildProcessorSection(BuildContext context) {
    return RootifyCard(
      title: "Processor",
      icon: LucideIcons.cpu,
      child: _ProcessorRealtimeInfo(theme: Theme.of(context)),
    );
  }

  Widget _buildGraphicsSection(BuildContext context) {
    return RootifyCard(
      title: "Graphics",
      icon: LucideIcons.monitor,
      child: _GpuInfo(theme: Theme.of(context)),
    );
  }

  Widget _buildMemorySection(BuildContext context) {
    return RootifyCard(
      title: "Memory",
      icon: LucideIcons.database,
      child: _MemoryRealtimeInfo(theme: Theme.of(context)),
    );
  }

  Widget _buildBatterySection(BuildContext context) {
    return RootifyCard(
      title: "Battery",
      icon: LucideIcons.battery,
      child: _BatteryRealtimeInfo(theme: Theme.of(context)),
    );
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

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return RootifySubCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16, color: theme.primaryColor.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

class _GpuInfo extends ConsumerWidget {
  final ThemeData theme;
  const _GpuInfo({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpuInfoAsync = ref.watch(gpuInfoProvider);

    return gpuInfoAsync.when(
      data: (gpu) => Column(
        children: [
          _DetailTile(
            icon: LucideIcons.factory,
            label: "Vendor",
            value: gpu.vendor,
            theme: theme,
          ),
          _DetailTile(
            icon: LucideIcons.component,
            label: "Renderer",
            value: gpu.renderer,
            theme: theme,
          ),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _DetailTile(
        icon: LucideIcons.alertTriangle,
        label: "GPU Info",
        value: "Unavailable",
        theme: theme,
      ),
    );
  }
}

class _ProcessorRealtimeInfo extends ConsumerWidget {
  final ThemeData theme;
  const _ProcessorRealtimeInfo({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(cpuMonitorStreamProvider);
    return snapshotAsync.when(
      data: (snapshot) {
        final clusters = snapshot.clusters.length;
        final cores = snapshot.cores.length;
        final govs =
            snapshot.clusters.map((c) => c.governor).toSet().join(" / ");

        return Column(
          children: [
            _DetailTile(
              icon: LucideIcons.layers,
              label: "Topology",
              value: "$clusters Clusters / $cores Cores",
              theme: theme,
            ),
            _DetailTile(
              icon: LucideIcons.activity,
              label: "Active Governors",
              value: govs.isEmpty ? "Unknown" : govs,
              theme: theme,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _DetailTile(
        icon: LucideIcons.alertTriangle,
        label: "Processor",
        value: "Communication Error",
        theme: theme,
      ),
    );
  }
}

class _MemoryRealtimeInfo extends ConsumerWidget {
  final ThemeData theme;
  const _MemoryRealtimeInfo({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(ramStreamProvider);

    return snapshotAsync.when(
      data: (snapshot) {
        return Column(
          children: [
            _MemoryGauge(
              title: 'RAM',
              totalMb: snapshot.ram.totalMb.toDouble(),
              usedMb: snapshot.ram.usedMb.toDouble(),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _MemoryGauge(
              title: 'ZRAM',
              totalMb: snapshot.zram.totalMb.toDouble(),
              usedMb: snapshot.zram.usedMb.toDouble(),
              theme: theme,
              isZram: true,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BatteryRealtimeInfo extends ConsumerWidget {
  final ThemeData theme;
  const _BatteryRealtimeInfo({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(batteryStreamProvider);

    return snapshotAsync.when(
      data: (snapshot) {
        return Column(
          children: [
            _DetailTile(
              icon: LucideIcons.thermometer,
              label: "Temperature",
              value: "${snapshot.temp.celsius.toStringAsFixed(1)}°C",
              theme: theme,
            ),
            _DetailTile(
              icon: LucideIcons.zap,
              label: "Current Draw",
              value: "${snapshot.current.now} mA",
              theme: theme,
            ),
            _DetailTile(
              icon: LucideIcons.heartPulse,
              label: "Battery Health",
              value: snapshot.health.status,
              theme: theme,
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MemoryGauge extends StatelessWidget {
  final String title;
  final double totalMb;
  final double usedMb;
  final ThemeData theme;
  final bool isZram;

  const _MemoryGauge({
    required this.title,
    required this.totalMb,
    required this.usedMb,
    required this.theme,
    this.isZram = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalMb <= 0 ? 1.0 : totalMb;
    final progress = (usedMb / safeTotal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(0);

    final totalGb = (totalMb / 1024).toStringAsFixed(1);
    final usedGb = (usedMb / 1024).toStringAsFixed(1);

    Color progressColor = theme.primaryColor;
    if (progress > 0.85) {
      progressColor = Colors.redAccent;
    } else if (progress > 0.6) {
      progressColor = Colors.orangeAccent;
    }

    return RootifySubCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isZram ? LucideIcons.hardDrive : LucideIcons.memoryStick,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(title.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: theme.colorScheme.onSurface,
                      )),
                ],
              ),
              Text("$percentage%",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: progressColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Used: ${usedGb}GB", style: theme.textTheme.bodySmall),
              Text("Total: ${totalGb}GB", style: theme.textTheme.bodySmall),
            ],
          )
        ],
      ),
    );
  }
}
