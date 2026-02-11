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
// Dynamic Mesh Background for FPSGO Dashboard
class FpsGoBackground extends StatelessWidget {
  const FpsGoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Configuration
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- Component Assembly
    return Positioned.fill(
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
            // --- Sub
            // Primary Animated Glow
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

            // --- Sub
            // Secondary Accent Flow
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
    );
  }
}
