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
import 'package:flutter_animate/flutter_animate.dart';

// ---- MAJOR ---
// Status Bar Animation Wrapper
class StatusBarAnimation extends StatefulWidget {
  // --- Parameters
  final Widget child;
  const StatusBarAnimation({super.key, required this.child});

  @override
  State<StatusBarAnimation> createState() => _StatusBarAnimationState();
}

class _StatusBarAnimationState extends State<StatusBarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.8, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

// ---- MAJOR ---
// System Status Bar Animations Constants
class SystemStatusBarAnimations {
  static const Duration statusBarFade = Duration(milliseconds: 600);

  // --- Root Status Pulse Effect
  static List<Effect> rootStatusPulse() {
    return [
      ScaleEffect(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.2, 1.2),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      ),
      FadeEffect(
        begin: 0.5,
        end: 0.0,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOut,
      ),
    ];
  }
}

// ---- MAJOR ---
// Theme Button Transition (Telegram-style Rotation + Scale)
class ThemeButtonTransition extends StatelessWidget {
  final Widget child;

  const ThemeButtonTransition({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ---- MAJOR ---
// Bouncing Button Animation
class BouncingButton extends StatefulWidget {
  // --- Parameters
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  // --- Animation Controls
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        reverseDuration: const Duration(milliseconds: 100));

    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Interaction Logic
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  // --- Build
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
