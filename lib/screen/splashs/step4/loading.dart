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
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../../../providers/addons_provider.dart';
import '../../../providers/cpu_provider.dart';
import '../../../providers/fpsgo_provider.dart';
import '../../../providers/shared_prefs_provider.dart';
import '../../../services/vendor.dart';
import '../../../services/shell_services.dart';
import '../../../shell/shell_zram.dart';
import '../../../shell/shell_swappiness.dart';
import '../../../widgets/toast.dart';
import '../../../widgets/typography.dart';
import '../../../animations/splashscreen_animation.dart';

// ---- MAJOR ---
// Async Data Loading Page
class LoadingPage extends ConsumerStatefulWidget {
  final VoidCallback onFinished;

  const LoadingPage({super.key, required this.onFinished});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

// ---- MAJOR ---
// Loading State & System Initialization Logic
class _LoadingPageState extends ConsumerState<LoadingPage>
    with TickerProviderStateMixin {
  // --- Fields
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  String _status = 'Initializing...';

  // --- Initialization
  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));

    // Detail: Defer loading to next frame for stable provider access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmupAnimations();
      _performRealLoading();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // --- Sub
  // Animation Pipeline Warmup
  void _warmupAnimations() {
    // Detail: Forces controllers to build pipelines early to prevent jank
    _rotationController.forward(from: 0);
    _pulseController.forward(from: 0);
  }

  // --- Sub
  // Core System Setup Sequence
  Future<void> _performRealLoading() async {
    if (mounted) setState(() => _status = 'Initializing...');

    // Detail: Global Warmup - Start loading data & shells in parallel
    RootifyToast.show(context, 'Warming up System Core...');

    final shellWarmup = ref.read(shellServiceProvider).warmup();
    final moduleLoader = ref.read(moduleStateProvider.notifier).loadStatus();
    final vendorLoader = ref.read(vendorInfoProvider.future);

    // CPU & FPSGO initialization
    final cpuLoader = ref.read(cpuStateProvider.notifier).loadData();
    final fpsgoNotifier = ref.read(fpsGoStateProvider.notifier);
    final fpsgoLoad = fpsgoNotifier.loadData();
    final fpsgoWarmup = fpsgoLoad.then((_) => fpsgoNotifier.warmup());

    // ZRAM & Swappiness shell warmup
    final zramShell = ref.read(zramShellProvider);
    final swapShell = ref.read(swappinessShellProvider);

    final zramSizeLoader = zramShell.getZramSize();
    final totalRamLoader = zramShell.getTotalRam();
    final activeAlgoLoader = zramShell.getActiveAlgorithm();
    final vfsPressureLoader = swapShell.getVfsCachePressure();

    // Progress Animation: Continuous glide to 90%
    _progressController.animateTo(0.9,
        duration: const Duration(milliseconds: 2500), curve: Curves.linear);

    _updateStatusDelayed('Loading Core Data...', 400);
    _updateStatusDelayed('Optimizing CPU & Memory...', 1000);
    _updateStatusDelayed('Verifying FPSGO Profile...', 1600);
    _updateStatusDelayed('Finalizing Shell...', 2200);

    // Wait for all critical background tasks (5s timeout fallback)
    await Future.wait<Object?>([
      moduleLoader,
      shellWarmup,
      cpuLoader,
      vendorLoader,
      fpsgoLoad,
      fpsgoWarmup,
      zramSizeLoader,
      totalRamLoader,
      activeAlgoLoader,
      vfsPressureLoader,
    ]).timeout(const Duration(seconds: 5), onTimeout: () => []);

    // Persist warmup state
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('app_warmed_up', true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _status = 'Ready...');
      // Final snap to 100% progress
      await _progressController.animateTo(1.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

      if (mounted) {
        widget.onFinished();
      }
    }
  }

  // --- Sub
  // Status Text Update Managed Delay
  void _updateStatusDelayed(String text, int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    if (mounted) {
      setState(() => _status = text);
    }
  }

  // --- UI Builder
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background effect: Floating particles
          ...List.generate(
              20, (index) => _buildParticle(index, primaryColor, screenSize)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedLogo(primaryColor),
                const SizedBox(height: 48),
                _buildBranding(colorScheme),
                const SizedBox(height: 64),
                _buildProgressBar(colorScheme, primaryColor),
                const SizedBox(height: 20),
                _buildStatusText(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Custom Animated Logo Component
  Widget _buildAnimatedLogo(Color primaryColor) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Rotating Ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) => Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) => CustomPaint(
                    painter: _ArcPainter(
                      color: primaryColor,
                      progress: _progressController.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Inner Pulsing Ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: 0.7 + (_pulseController.value * 0.1),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: primaryColor.withValues(
                        alpha: 0.3 * (1 - _pulseController.value)),
                  ),
                ),
              ),
            ),
          ),
          // Drawn Path Logo Animation
          SizedBox(
            width: 80,
            height: 80,
            child: SplashScreenAnimation.drawPathAnimation(
              path:
                  SplashScreenAnimation.getOfficialLogoPath(const Size(80, 80)),
              color: primaryColor,
              duration: const Duration(seconds: 3),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub
  // Branding Header Section
  Widget _buildBranding(ColorScheme colorScheme) {
    return Column(
      children: [
        SplashScreenAnimation.appNameEntrance(
          Text(
            'ROOTIFY',
            style: RootifyTypography.adaptiveHeader(context).copyWith(
                fontSize: 32, letterSpacing: 6.0, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        SplashScreenAnimation.taglineFadeIn(
          Text(
            'System Control Center',
            style: RootifyTypography.adaptiveCaption(context).copyWith(
              letterSpacing: 2.0,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  // --- Sub
  // Dynamic Progress Visualization
  Widget _buildProgressBar(ColorScheme colorScheme, Color primaryColor) {
    return SplashScreenAnimation.progressBarEntrance(
      Container(
        width: 240,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressController.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.7)
                ]),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Sub
  // Status Text Component
  Widget _buildStatusText(Color primaryColor) {
    return SplashScreenAnimation.statusTextChange(
      Text(
        _status,
        style: RootifyTypography.adaptiveCaption(context).copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
      _status,
    );
  }

  // --- Sub
  // Particle Generation Utility
  Widget _buildParticle(int index, Color primaryColor, Size screenSize) {
    final random = math.Random(index);
    final left = random.nextDouble() * screenSize.width;
    final top = random.nextDouble() * screenSize.height;
    final size = 2.0 + (random.nextDouble() * 4);
    final duration = 3000 + random.nextInt(2000);
    return Positioned(
      left: left,
      top: top,
      child: SplashScreenAnimation.floatingParticle(
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1), blurRadius: 4)
            ],
          ),
        ),
        duration,
      ),
    );
  }
}

// ---- MAJOR ---
// Custom Progress Arc Painter
class _ArcPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
