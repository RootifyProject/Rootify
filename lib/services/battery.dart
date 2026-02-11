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
// Battery Metric Containers for State Management
// --- Sub
// Temperature State
class BatteryTemp {
  final double celsius;
  const BatteryTemp(this.celsius);
}

// --- Sub
// Current Flow State
class BatteryCurrent {
  final int now;
  final int average;
  const BatteryCurrent({required this.now, required this.average});
}

// --- Sub
// Capacity Tracking State
class BatteryCapacity {
  final int percentage;
  final int? remainingAh;
  const BatteryCapacity(this.percentage, [this.remainingAh]);
}

// --- Sub
// Charging Presence State
class BatteryStatus {
  final bool isCharging;
  final String label;
  const BatteryStatus({required this.isCharging, required this.label});
}

// --- Sub
// Voltage State
class BatteryVoltage {
  final double volts;
  const BatteryVoltage(this.volts);
}

// --- Sub
// Health Indicator State
class BatteryHealth {
  final String status;
  const BatteryHealth(this.status);
}

// --- Sub
// Technology Label State
class BatteryTech {
  final String type;
  const BatteryTech(this.type);
}

// --- Sub
// Temporal Projection State
class BatteryTime {
  final Duration? remaining; // To full or to empty
  const BatteryTime(this.remaining);
}

// --- Sub
// Consolidated Point-in-time state
class BatterySnapshot {
  final BatteryTemp temp;
  final BatteryCurrent current;
  final BatteryCapacity capacity;
  final BatteryStatus status;
  final BatteryVoltage voltage;
  final BatteryHealth health;
  final BatteryTech tech;
  final BatteryTime time;
  final DateTime timestamp;

  BatterySnapshot({
    required this.temp,
    required this.current,
    required this.capacity,
    required this.status,
    required this.voltage,
    required this.health,
    required this.tech,
    required this.time,
  }) : timestamp = DateTime.now();
}

// ---- MAJOR ---
// Heartbeat Engine for Power Supply Monitoring
class BatteryMonitoringService {
  // --- Sub
  // Singleton Pattern
  static final BatteryMonitoringService _instance =
      BatteryMonitoringService._internal();
  factory BatteryMonitoringService() => _instance;
  BatteryMonitoringService._internal();

  // --- Sub
  // Private Logic Containers
  Timer? _timer;
  final _controller = StreamController<BatterySnapshot>.broadcast();
  ShellService? _shell;
  bool _initialized = false;

  // --- Sub
  // Public Accessors
  Stream<BatterySnapshot> get stream => _controller.stream;

  // --- Sub
  // Lifecycle Handlers
  void init(ShellService shell) {
    _shell = shell;
  }

  void start() {
    if (_timer != null) return;
    _initialized = true;
    // Increased to 1s to reduce root shell overhead
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
      // Comment: Batch read all necessary nodes in one shell call to avoid SELinux denials and overhead
      const separator = "|||";
      final cmd = [
        'cat /sys/class/power_supply/battery/temp 2>/dev/null',
        'cat /sys/class/power_supply/battery/current_now 2>/dev/null',
        'cat /sys/class/power_supply/battery/current_avg 2>/dev/null',
        'cat /sys/class/power_supply/battery/capacity 2>/dev/null',
        'cat /sys/class/power_supply/battery/status 2>/dev/null',
        'cat /sys/class/power_supply/battery/voltage_now 2>/dev/null',
        'cat /sys/class/power_supply/battery/health 2>/dev/null',
        'cat /sys/class/power_supply/battery/technology 2>/dev/null',
        'cat /sys/class/power_supply/battery/time_to_full_now 2>/dev/null',
      ].join('; echo "$separator"; ');

      final output = await _shell!.exec(cmd, canSkip: true);
      if (output.isEmpty) return;

      final sections = output.split(separator);
      if (sections.length < 9) return;

      // Comment: Parse and normalize raw values
      final rawTemp = int.tryParse(sections[0].trim()) ?? 0;
      final rawCurrent = int.tryParse(sections[1].trim()) ?? 0;
      final rawAvg = int.tryParse(sections[2].trim()) ?? 0;
      final rawCap = int.tryParse(sections[3].trim()) ?? 0;
      final rawStatus = sections[4].trim();
      final rawVolt = int.tryParse(sections[5].trim()) ?? 0;
      final rawHealth = sections[6].trim();
      final rawTech = sections[7].trim();
      final rawTimeFull = int.tryParse(sections[8].trim()) ?? -1;

      final snapshot = BatterySnapshot(
        temp: BatteryTemp(rawTemp / 10),
        current: BatteryCurrent(
          now: (rawCurrent / 1000).round(),
          average: (rawAvg / 1000).round(),
        ),
        capacity: BatteryCapacity(rawCap),
        status: BatteryStatus(
          isCharging: rawStatus.toLowerCase() == 'charging',
          label: _sanitize(rawStatus),
        ),
        voltage: BatteryVoltage(rawVolt / 1000000),
        health: BatteryHealth(_sanitize(rawHealth)),
        tech: BatteryTech(_sanitize(rawTech)),
        time: BatteryTime(
            rawTimeFull > 0 ? Duration(seconds: rawTimeFull) : null),
      );

      if (!_controller.isClosed) _controller.add(snapshot);
    } catch (_) {
      // Comment: Handle silent fail to prevent spam
    }
  }

  // --- Sub
  // String Utilities
  String _sanitize(String value) {
    final v = value.trim();
    return v.isEmpty ? '—' : v;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final batteryMonitor = BatteryMonitoringService();

final batteryStreamProvider = StreamProvider<BatterySnapshot>((ref) {
  final shell = ref.watch(shellServiceProvider);
  batteryMonitor.init(shell);
  batteryMonitor.start();
  ref.onDispose(() => batteryMonitor.stop());
  return batteryMonitor.stream;
});
