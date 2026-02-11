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

// ---- EXPORTS ---
export 'dock_animation.dart';
export 'statusbar_animation.dart';
export 'splashscreen_animation.dart';

// ---- MAJOR ---
// Rootify Animations Utility
class RootifyAnimations {
  // --- Constants
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration fast = Duration(milliseconds: 200);
  static const Curve easeInOut = Curves.easeInOut;
}
