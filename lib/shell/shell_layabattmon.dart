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

// ---- EXTERNAL ---
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- LOCAL ---
import '../shell/base_shell.dart';
import '../shell/shellsession.dart';
import '../utils/app_logger.dart';

// ---- MAJOR ---
// Bridge for Laya Battery Monitoring Service
class LayaBattmonShellService extends BaseShellService {
  LayaBattmonShellService(super.session);

  // --- Sub
  // Process Identity & Matching Patterns
  static const String binBM = "laya-battery-monitor";
  static const String patternBM = "laya.*batt";

  // --- Sub
  // Runtime Visibility Logic
  Future<bool> isBatteryMonitorRunning() => _isProcessRunning(binBM, patternBM);

  Future<bool> _isProcessRunning(String binName, String pattern) async {
    try {
      final pid = await getPID(binName, pattern);
      return pid != null;
    } catch (e) {
      return false;
    }
  }

  Future<int?> getPID(String binName, String pattern) async {
    try {
      // Comment: Try pidof (highest priority/performance)
      final pidof = await exec("pidof $binName", silent: true);
      if (pidof.trim().isNotEmpty) {
        return int.tryParse(pidof.trim().split(' ')[0]);
      }

      // Comment: Try pgrep (secondary for pattern-based discovery)
      final pgrep = await exec("pgrep -f \"$pattern\"", silent: true);
      if (pgrep.trim().isNotEmpty) {
        return int.tryParse(pgrep.trim().split('\n')[0]);
      }

      // Comment: Try ps (standard fallback for restricted kernels)
      final ps = await exec("ps -A | grep -i \"$pattern\" | grep -v grep",
          silent: true);
      if (ps.trim().isNotEmpty) {
        final parts = ps.trim().split(RegExp(r'\s+'));
        if (parts.length > 1) return int.tryParse(parts[1]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Sub
  // Execution Control Handlers
  Future<void> startBatteryMonitor() async {
    logger.i("LayaBMShell: Initiating Battery Monitor daemon...");
    await _startBinary(binBM);
  }

  Future<bool> stopBatteryMonitor() async {
    logger.w("LayaBMShell: Terminating Battery Monitor daemon...");
    await _stopProcess(binBM, patternBM);
    return true;
  }

  // --- Sub
  // Telemetry & Log Retrieval
  Future<String> getBMLogs() => _getLogs(binBM, "LayaBatteryMonitor");

  Future<void> clearBMLogs() => _clearLogs(binBM);

  // --- Sub
  // Private Bridge Utilities
  Future<void> _startBinary(String binName) async {
    final path = "/data/data/com.aby.rootify/files/bin/$binName";
    final logDir = "/data/data/com.aby.rootify/files/logs/";
    final logFile = "$logDir$binName.log";

    // Comment: Chained setup and execution to minimize bridge latency
    await exec(
        "mkdir -p $logDir && chmod +x $path && ($path > $logFile 2>&1 &)",
        silent: true);
  }

  Future<void> _stopProcess(String binName, String pattern) async {
    // Comment: Staged termination sequence (SIGKILL)
    await exec("pkill -9 -f \"$pattern\"");
    await exec("killall -9 $binName 2>/dev/null || true");

    final pids = await exec("pgrep -f \"$pattern\"");
    if (pids.trim().isNotEmpty) {
      for (final pid in pids.split('\n')) {
        if (pid.trim().isNotEmpty) {
          await exec("kill -9 ${pid.trim()} 2>/dev/null || true");
        }
      }
    }
  }

  Future<String> _getLogs(String binName, String tag) async {
    final logPath = "/data/data/com.aby.rootify/files/logs/$binName.log";

    // Comment: 1. Attempt retrieval from dedicated filesystem log
    if ((await exec("test -f $logPath && echo 'YES'")).contains("YES")) {
      final content = await exec("cat $logPath");
      if (content.trim().isNotEmpty) return content;
    }

    // Comment: 2. Fallback to dmesg/logcat with precise tag filtering
    final logs = await exec("logcat -d -s $tag | tail -n 100 || true");
    final filtered =
        logs.split('\n').where((l) => !l.startsWith('---------')).join('\n');
    if (filtered.trim().isNotEmpty) return filtered;

    return "Waiting for logs...";
  }

  Future<void> _clearLogs(String binName) async {
    final logPath = "/data/data/com.aby.rootify/files/logs/$binName.log";
    await exec("truncate -s 0 $logPath || > $logPath");
    await exec("logcat -b all -c");
  }
}

// ---- MAJOR ---
// Global Providers
final layabattmonShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return LayaBattmonShellService(session);
});
