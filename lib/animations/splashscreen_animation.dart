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
import 'package:flutter_animate/flutter_animate.dart';

// ---- MAJOR ---
// Splash Screen Animations Controller
class SplashScreenAnimation {
  // ---- SUB ---
  // Logo Drawing (Stroke Animation)
  static Widget drawPathAnimation({
    required Path path,
    required Color color,
    required Duration duration,
  }) {
    return _AnimatedPath(
      path: path,
      color: color,
      duration: duration,
    );
  }

  // ---- SUB ---
  // Transcribed Official Logo Path
  // ViewBox: 0 0 281 261
  static Path getOfficialLogoPath(Size size) {
    final path = Path();

    // --- Subpath 1
    // Outer Shape
    path.moveTo(279.952, 250.759);
    path.lineTo(208.639, 101.709);
    path.cubicTo(183.476, 120.715, 160.211, 154.395, 159.528, 182.238);
    path.lineTo(181.163, 226.465);
    path.cubicTo(181.942, 228.053, 183.36, 229.286, 185.138, 229.929);
    path.lineTo(269.659, 260.319);
    path.cubicTo(276.103, 262.644, 282.695, 256.493, 279.952, 250.759);
    path.close();

    // --- Subpath 2
    // Inner Shape
    path.moveTo(139.739, 167.831);
    path.cubicTo(139.511, 168.119, 139.304, 168.401, 139.105, 168.722);
    path.lineTo(104.556, 224.854);
    path.cubicTo(103.578, 226.434, 101.973, 227.669, 100.077, 228.267);
    path.lineTo(10.0487, 256.667);
    path.cubicTo(3.36606, 258.795, -2.39583, 252.542, 1.00974, 246.885);
    path.lineTo(147.969, 3.86208);
    path.cubicTo(151.136, -1.34622, 159.372, -1.27041, 161.904, 3.9904);
    path.lineTo(206.212, 96.6249);
    path.cubicTo(177.376, 114.115, 154.065, 138.844, 139.739, 167.831);
    path.close();

    // --- Scale & Center Logic
    // Handles responsiveness for various size constraints
    final bounds = path.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return path;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = math.min(scaleX, scaleY);
    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;

    // --- Centering Offsets
    final dx = (size.width - scaledWidth) / 2 - (bounds.left * scale);
    final dy = (size.height - scaledHeight) / 2 - (bounds.top * scale);

    final Matrix4 matrix = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));

    return path.transform(matrix.storage);
  }

  // ---- SUB ---
  // Loading Indicator (Moving Sliders)
  static Widget movingSliders(Color color, Size size) {
    return _MovingSliders(color, size);
  }

  // ---- SUB ---
  // Welcome Animation (Rocket)
  static Widget rocketStanding(Widget child) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // --- Smoke Particles
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: SizedBox(
            height: 60,
            child: _RocketSmoke(),
          ),
        ),
        // --- Hovering Rocket
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: child.animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
              begin: 0,
              end: -15,
              duration: 2500.ms,
              curve: Curves.easeInOutSine),
        )
      ],
    );
  }

  // ---- SUB ---
  // Safety/Warning (RGB Border)
  static Widget lightRunning(Widget child) {
    return _RGBBorderRunning(child);
  }

  // ---- SUB ---
  // Utility Animations (Helpers)
  static Widget glowingShield(Widget child, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final iconColor =
            (child is Icon) ? child.color ?? Colors.white : Colors.white;
        return Container(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(
              color:
                  iconColor.withValues(alpha: 0.2 + (0.3 * controller.value)),
              blurRadius: 20 + (10 * controller.value),
              spreadRadius: 5 + (5 * controller.value),
            )
          ]),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget titleSlideIn(Widget child) => child
      .animate()
      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
      .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOut);

  static Widget descriptionSlideIn(Widget child) => child
      .animate()
      .fadeIn(delay: 200.ms, duration: 600.ms)
      .moveY(begin: 20, end: 0, duration: 600.ms, curve: Curves.easeOut);

  static Widget pulsingStatus(Widget child) => child
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .fade(begin: 0.6, end: 1.0, duration: 800.ms);

  static Widget warningCardSlideUp(Widget child) => child
      .animate()
      .fadeIn(duration: 500.ms)
      .moveY(begin: 50, end: 0, duration: 500.ms, curve: Curves.easeOutBack);

  static Widget buttonScaleIn(Widget child) =>
      child.animate().fadeIn(delay: 400.ms, duration: 400.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut);

  static Widget appNameEntrance(Widget child) => child
      .animate()
      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
      .moveY(begin: 20, end: 0, duration: 800.ms, curve: Curves.easeOut);

  static Widget taglineFadeIn(Widget child) => child
      .animate()
      .fadeIn(delay: 400.ms, duration: 800.ms, curve: Curves.easeOut);

  static Widget progressBarEntrance(Widget child) =>
      child.animate().fadeIn(delay: 800.ms, duration: 600.ms).scaleX(
          begin: 0,
          end: 1,
          alignment: Alignment.centerLeft,
          duration: 600.ms,
          curve: Curves.easeOut);

  static Widget statusTextChange(Widget child, String key) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(key), child: child),
      );

  static Widget floatingParticle(Widget child, int durationMs) => child
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .move(
          begin: const Offset(-5, -5),
          end: const Offset(5, 5),
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeInOutSine)
      .fadeIn(duration: 1000.ms);

  static Widget pageContentFade(Widget child, bool isActive,
      {int delayMs = 0}) {
    if (!isActive) return const SizedBox();
    return child
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 500.ms)
        .moveY(begin: 20, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  static Widget checkboxCardSlideIn(Widget child, bool isActive) {
    if (!isActive) return const SizedBox();
    return child
        .animate()
        .fadeIn(delay: 600.ms, duration: 500.ms)
        .moveX(begin: 40, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ---- MAJOR ---
// Animated Path (Logo)
class _AnimatedPath extends StatefulWidget {
  final Path path;
  final Color color;
  final Duration duration;
  const _AnimatedPath(
      {required this.path, required this.color, required this.duration});

  @override
  State<_AnimatedPath> createState() => _AnimatedPathState();
}

class _AnimatedPathState extends State<_AnimatedPath>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Optimization
    // Isolates repaints
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _PathPainter(widget.path, widget.color, _controller.value),
        ),
      ),
    );
  }
}

// ---- MAJOR ---
// Path Painter
class _PathPainter extends CustomPainter {
  // --- Parameters
  final Path path;
  final Color color;
  final double progress;

  // --- Paint Cache
  // Avoid allocation per frame (Performance)
  late final Paint _linePaint;
  late final Paint _tipPaint;

  _PathPainter(this.path, this.color, this.progress) {
    _linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    _tipPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extract, _linePaint);

      if (progress < 1.0) {
        // --- Glowing tip effect
        final end = metric.getTangentForOffset(metric.length * progress);
        if (end != null) {
          canvas.drawCircle(end.position, 4, _tipPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress;
}

// ---- MAJOR ---
// Moving Sliders (Loading)
class _MovingSliders extends StatefulWidget {
  final Color color;
  final Size size;
  const _MovingSliders(this.color, this.size);
  @override
  State<_MovingSliders> createState() => _MovingSlidersState();
}

class _MovingSlidersState extends State<_MovingSliders>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
                size: widget.size,
                painter: _SlidersPainter(widget.color, _controller.value),
              )),
    );
  }
}

// ---- MAJOR ---
// Sliders Painter
class _SlidersPainter extends CustomPainter {
  // --- Parameters
  final Color color;
  final double progress;

  // --- Paint Cache
  final Paint _trackPaint;
  final Paint _knobPaint;

  _SlidersPainter(this.color, this.progress)
      : _trackPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
        _knobPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    const trackPadding = 10.0;
    final gaps = h / 4;

    for (int i = 0; i < 3; i++) {
      final y = gaps * (i + 1);

      // --- Draw Track
      canvas.drawLine(
          Offset(trackPadding, y), Offset(w - trackPadding, y), _trackPaint);

      // --- Calculate Logic
      double p = progress;
      if (i == 1) p = 1.0 - progress; // Middle slider opposes others
      if (i == 2) p = (progress + 0.3) % 1.0; // Offset phase

      // --- Sine wave ease
      // Creates organic movement
      final sine = (math.sin(p * math.pi * 2) + 1) / 2;
      final knobX = trackPadding + (w - 2 * trackPadding) * sine;

      canvas.drawCircle(Offset(knobX, y), 10, _knobPaint);
    }
  }

  @override
  bool shouldRepaint(_SlidersPainter old) => old.progress != progress;
}

// ---- MAJOR ---
// Rocket Smoke (Particle)
class _RocketSmoke extends StatefulWidget {
  @override
  State<_RocketSmoke> createState() => _RocketSmokeState();
}

class _RocketSmokeState extends State<_RocketSmoke>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(painter: _CloudPainter(_ctrl.value)),
      ),
    );
  }
}

// ---- MAJOR ---
// Cloud Painter
class _CloudPainter extends CustomPainter {
  // --- Parameters
  final double t;

  // --- Paint Cache
  final Paint _flamePaint = Paint()..style = PaintingStyle.fill;

  _CloudPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.2;

    for (int i = 0; i < 6; i++) {
      // --- Logic
      // Particles move down and spread out
      double offset = (t + i / 6.0) % 1.0;
      double dy = offset * size.height;
      double spread = (offset * 20.0) * (i % 2 == 0 ? 1 : -1);
      double radius = 8.0 * (1.0 - offset);

      _flamePaint.color =
          Colors.orange.withValues(alpha: (1.0 - offset).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx + spread, cy + dy), radius, _flamePaint);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => true; // Always animate
}

// ---- MAJOR ---
// RGB Border
class _RGBBorderRunning extends StatefulWidget {
  final Widget child;
  const _RGBBorderRunning(this.child);
  @override
  State<_RGBBorderRunning> createState() => _RGBBorderRunningState();
}

class _RGBBorderRunningState extends State<_RGBBorderRunning>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          foregroundPainter: _RGBPainter(_ctrl.value),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---- MAJOR ---
// RGB Painter
class _RGBPainter extends CustomPainter {
  // --- Parameters
  final double progress;

  // --- Colors
  static const List<Color> _colors = [
    Colors.red,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.red
  ];

  _RGBPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // --- Layout
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    final snakeLen = totalLength * 0.3; // Length of the "light"

    final start = totalLength * progress;
    final end = start + snakeLen;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      // --- Shader Integration
      // Gradient rotates based on progress
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: _colors,
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Offset.zero & size);

    // --- Draw segment
    // Handles wrap-around logic
    if (end > totalLength) {
      final p1 = metrics.extractPath(start, totalLength);
      final p2 = metrics.extractPath(0, end - totalLength);
      canvas.drawPath(p1, paint);
      canvas.drawPath(p2, paint);
    } else {
      final p = metrics.extractPath(start, end);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_RGBPainter old) => old.progress != progress;
}
