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
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ---- LOCAL ---
import '../theme/theme_provider.dart';

/// Master Transition Wrapper
/// Consolidates Theme (Circular Reveal) and Style (Horizontal Wipe)
/// into a single RepaintBoundary to reduce GPU buffer pressure.
class MasterTransition extends StatefulWidget {
  final Widget child;

  const MasterTransition({
    super.key,
    required this.child,
  });

  static MasterTransitionState of(BuildContext context) {
    return context.findAncestorStateOfType<MasterTransitionState>()!;
  }

  @override
  State<MasterTransition> createState() => MasterTransitionState();
}

class MasterTransitionState extends State<MasterTransition>
    with TickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();

  // Theme (Light/Dark)
  late AnimationController _themeController;
  ui.Image? _oldThemeImg;
  ui.Image? _newThemeImg;
  Offset _themeCenter = Offset.zero;

  // Style (Aurora/MD3)
  late AnimationController _styleController;
  ui.Image? _oldStyleImg;
  ui.Image? _newStyleImg;
  bool _isMovingToAurora = false;

  @override
  void initState() {
    super.initState();
    _themeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _oldThemeImg = null;
            _newThemeImg = null;
          });
        }
      });

    _styleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _oldStyleImg = null;
            _newStyleImg = null;
          });
        }
      });
  }

  @override
  void dispose() {
    _themeController.dispose();
    _styleController.dispose();
    _oldThemeImg?.dispose();
    _newThemeImg?.dispose();
    _oldStyleImg?.dispose();
    _newStyleImg?.dispose();
    super.dispose();
  }

  // --- Theme Change Logic
  Future<void> changeTheme({
    required Offset position,
    required VoidCallback onThemeChanged,
  }) async {
    if (_themeController.isAnimating ||
        _styleController.isAnimating ||
        !mounted) {
      return;
    }

    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      onThemeChanged();
      return;
    }

    try {
      final pixelRatio = math.min(MediaQuery.of(context).devicePixelRatio, 2.0);
      final oldImage = await boundary.toImage(pixelRatio: pixelRatio);

      setState(() {
        _oldThemeImg = oldImage;
        _themeCenter = position;
      });

      onThemeChanged();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        final newImage = await boundary.toImage(pixelRatio: pixelRatio);
        setState(() => _newThemeImg = newImage);
        _themeController.forward(from: 0.0);
      });
    } catch (_) {
      onThemeChanged();
    }
  }

  // --- Style Change Logic
  Future<void> changeStyle({
    required AppVisualStyle targetStyle,
    required VoidCallback onStyleChanged,
  }) async {
    if (_styleController.isAnimating ||
        _themeController.isAnimating ||
        !mounted) {
      return;
    }

    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      onStyleChanged();
      return;
    }

    try {
      final pixelRatio = math.min(MediaQuery.of(context).devicePixelRatio, 2.0);
      final oldImage = await boundary.toImage(pixelRatio: pixelRatio);

      setState(() {
        _oldStyleImg = oldImage;
        _isMovingToAurora = targetStyle == AppVisualStyle.aurora;
      });

      onStyleChanged();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted) return;
        final newImage = await boundary.toImage(pixelRatio: pixelRatio);
        setState(() => _newStyleImg = newImage);
        _styleController.forward(from: 0.0);
      });
    } catch (_) {
      onStyleChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: widget.child,
        ),

        // --- Theme Layers
        if (_oldThemeImg != null)
          Positioned.fill(
              child: RawImage(image: _oldThemeImg, fit: BoxFit.cover)),
        if (_newThemeImg != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _themeController,
              builder: (context, child) {
                final val =
                    Curves.easeInOutCubic.transform(_themeController.value);
                return ClipPath(
                  clipper: _CircularRevealClipper(
                      center: _themeCenter, fraction: val),
                  child: child,
                );
              },
              child: RawImage(image: _newThemeImg, fit: BoxFit.cover),
            ),
          ),

        // --- Style Layers
        if (_oldStyleImg != null)
          Positioned.fill(
              child: RawImage(image: _oldStyleImg, fit: BoxFit.cover)),
        if (_newStyleImg != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _styleController,
              builder: (context, child) {
                final val =
                    Curves.easeInOutCubic.transform(_styleController.value);
                return ClipPath(
                  clipper: _HorizontalRevealClipper(
                      fraction: val, fromLeft: _isMovingToAurora),
                  child: child,
                );
              },
              child: RawImage(image: _newStyleImg, fit: BoxFit.cover),
            ),
          ),
      ],
    );
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double fraction;
  _CircularRevealClipper({required this.center, required this.fraction});
  @override
  Path getClip(Size size) {
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxRadius * fraction));
  }

  @override
  bool shouldReclip(_CircularRevealClipper old) => old.fraction != fraction;
}

class _HorizontalRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final bool fromLeft;
  _HorizontalRevealClipper({required this.fraction, required this.fromLeft});
  @override
  Path getClip(Size size) {
    final path = Path();
    if (fromLeft) {
      path.addRect(Rect.fromLTWH(0, 0, size.width * fraction, size.height));
    } else {
      path.addRect(Rect.fromLTWH(size.width * (1.0 - fraction), 0,
          size.width * fraction, size.height));
    }
    return path;
  }

  @override
  bool shouldReclip(_HorizontalRevealClipper old) => old.fraction != fraction;
}
