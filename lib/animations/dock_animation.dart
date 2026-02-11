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

// ---- MAJOR ---
// Dock Animation Wrapper
class DockAnimation extends StatelessWidget {
  // --- Parameters
  final Widget child;
  final AnimationController controller;
  final double delay;

  const DockAnimation({
    super.key,
    required this.child,
    required this.controller,
    this.delay = 0.0,
  });

  // --- Build
  @override
  Widget build(BuildContext context) {
    // --- Slide Entrance
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      // --- Fade Entrance
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: controller,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }
}

// ---- MAJOR ---
// Dock Animations Constants
class DockAnimations {
  static const Duration activeTabSlide = Duration(milliseconds: 250);
  static const Duration iconBouncer = Duration(milliseconds: 300);
}

// ---- MAJOR ---
// Animated Dock Pill
class AnimatedDockPill extends StatelessWidget {
  // --- Parameters
  final bool isTapped;
  final double offset;
  final Widget child;

  const AnimatedDockPill({
    super.key,
    required this.isTapped,
    required this.offset,
    required this.child,
  });

  // --- Build
  @override
  Widget build(BuildContext context) {
    if (!isTapped) {
      // --- Swipe Mode
      // Direct Transform (Minimal Overhead)
      return Transform.translate(
        offset: Offset(offset, 0),
        child: child,
      );
    }

    // --- Tap Mode
    // Animated Interpolation
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: offset),
      duration: DockAnimations.activeTabSlide,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}
