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
import 'dart:async';

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../services/shell_services.dart';

// ---- MAJOR ---
// Unified System Resource Metrics (Simplified for FPS-only mode)
class SystemStats {
  final double fps;

  const SystemStats({
    this.fps = 0,
  });
}

// ---- MAJOR ---
// Global System Performance Observer (Optimized for FPS only)
final systemMonitorProvider =
    StreamProvider.autoDispose<SystemStats>((ref) async* {
  final shell = ref.read(shellServiceProvider);

  yield const SystemStats();

  // Comment: Optimized query command - ONLY fetches FPS
  const cmd =
      'dumpsys SurfaceFlinger --timestats -dump | grep "averageFPS" | head -n 1; '
      'dumpsys SurfaceFlinger --timestats -clear';

  while (true) {
    // Comment: Balanced Polling (1 second) to minimize battery drain
    await Future.delayed(const Duration(seconds: 1));

    try {
      final output = await shell.exec(cmd, canSkip: true);
      if (output.isEmpty) continue;

      double fps = 0;
      final line = output.trim();
      if (line.contains('=')) {
        fps = double.tryParse(line.split('=')[1].trim()) ?? 0;
      }

      yield SystemStats(fps: fps);
    } catch (e) {
      yield const SystemStats();
    }
  }
});
