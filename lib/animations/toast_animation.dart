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
// Toast Animations Utility
class ToastAnimations {
  // --- Entry Animation
  // Slide down from top + Fade In
  static List<Effect> entry({double beginY = -1.0}) {
    return [
      FadeEffect(duration: 300.ms, curve: Curves.easeOut),
      SlideEffect(
        begin: Offset(0, beginY),
        end: const Offset(0, 0),
        duration: 300.ms,
        curve: Curves.easeOutBack, // Slight bounce for personality
      ),
    ];
  }

  // --- Exit Animation
  // Slide up + Fade Out
  static List<Effect> exit({double endY = -1.0}) {
    return [
      FadeEffect(duration: 300.ms, curve: Curves.easeIn, end: 0.0),
      SlideEffect(
        begin: const Offset(0, 0),
        end: Offset(0, endY),
        duration: 300.ms,
        curve: Curves.easeIn,
      ),
    ];
  }
}
