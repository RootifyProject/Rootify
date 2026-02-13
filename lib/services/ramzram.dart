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
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Memory Metric Containers
// --- Sub
// Physical RAM Stats
class RamStats {
  final int totalMb;
  final int usedMb;
  final int availableMb;
  final double usedPercent;

  const RamStats({
    required this.totalMb,
    required this.usedMb,
    required this.availableMb,
    required this.usedPercent,
  });
}

// --- Sub
// Virtual ZRAM Stats
class ZramStats {
  final int totalMb;
  final int usedMb;
  final int freeMb;
  final double usedPercent;

  const ZramStats({
    required this.totalMb,
    required this.usedMb,
    required this.freeMb,
    required this.usedPercent,
  });
}

// --- Sub
// Consolidated Point-in-time Snapshot
class MemorySnapshot {
  final RamStats ram;
  final ZramStats zram;
  final DateTime timestamp;

  MemorySnapshot({
    required this.ram,
    required this.zram,
  }) : timestamp = DateTime.now();
}

// ---- MAJOR ---
// Heartbeat Engine for Memory Resource Monitoring
class RamMonitoringService {
  // --- Sub
  // Singleton Pattern
  static final RamMonitoringService _instance =
      RamMonitoringService._internal();
  factory RamMonitoringService() => _instance;
  RamMonitoringService._internal();

  // --- Sub
  // Private Logic Containers
  Timer? _timer;
  final _controller = StreamController<MemorySnapshot>.broadcast();
  ShellService? _shell;
  bool _initialized = false;

  // --- Sub
  // Public Accessors
  Stream<MemorySnapshot> get stream => _controller.stream;

  // --- Sub
  // Lifecycle Handlers
  void init(ShellService shell) {
    _shell = shell;
  }

  void start() {
    if (_timer != null) return;
    _initialized = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) => _tick());
    _tick(); // Immediate first tick
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // --- Sub
  // Asynchronous Polling Logic
  Future<void> _tick() async {
    if (!_initialized || _controller.isClosed || _shell == null) return;

    try {
      // Comment: Direct parsing of /proc/meminfo for highest accuracy
      final content = await _shell!.exec('cat /proc/meminfo', canSkip: true);
      if (content.isEmpty) return;

      final lines = content.split('\n');
      final data = <String, int>{};

      for (var line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(':');
        if (parts.length < 2) continue;

        final key = parts[0].trim();
        final valueStr = parts[1].trim().split(' ')[0];
        final value = int.tryParse(valueStr) ?? 0;
        data[key] = value; // in kB
      }

      // Comment: RAM Calculation logic
      final totalKb = data['MemTotal'] ?? 0;
      final availKb = data['MemAvailable'] ?? data['MemFree'] ?? 0;
      final usedKb = totalKb - availKb;

      final ram = RamStats(
        totalMb: (totalKb / 1024).round(),
        usedMb: (usedKb / 1024).round(),
        availableMb: (availKb / 1024).round(),
        usedPercent: totalKb > 0 ? (usedKb / totalKb) * 100 : 0.0,
      );

      // Comment: ZRAM (Swap) Calculation logic
      final swapTotalKb = data['SwapTotal'] ?? 0;
      final swapFreeKb = data['SwapFree'] ?? 0;
      final swapUsedKb = swapTotalKb - swapFreeKb;

      final zram = ZramStats(
        totalMb: (swapTotalKb / 1024).round(),
        usedMb: (swapUsedKb / 1024).round(),
        freeMb: (swapFreeKb / 1024).round(),
        usedPercent: swapTotalKb > 0 ? (swapUsedKb / swapTotalKb) * 100 : 0.0,
      );

      final snapshot = MemorySnapshot(ram: ram, zram: zram);
      if (!_controller.isClosed) _controller.add(snapshot);
    } catch (e) {
      // Comment: Silent error handler to prevent UI flickering during shell warmups
      // Only log as warning locally, do not auto-report
      if (_initialized) {
        // weak check to avoid log spam on dispose
        logger.w("RamMonitor: $e"); // Optional: uncomment if needed for debugging
      }
    }
  }

  // --- Sub
  // Service Cleanup
  void dispose() {
    stop();
    _controller.close();
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final ramMonitor = RamMonitoringService();

final ramStreamProvider = StreamProvider<MemorySnapshot>((ref) {
  final shell = ref.watch(shellServiceProvider);
  ramMonitor.init(shell);
  ramMonitor.start();
  ref.onDispose(() => ramMonitor.stop());
  return ramMonitor.stream;
});
