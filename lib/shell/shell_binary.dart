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
// Binary Execution & Lifecycle Management
class BinaryShellService extends BaseShellService {
  BinaryShellService(super.session);

  // --- Sub
  // Constants & Paths
  static const String binPath = "/data/data/com.aby.rootify/files/bin";
  static const String logPath = "/data/data/com.aby.rootify/files/logs";

  // --- Sub
  // Process Lifecycle
  Future<void> run(String binaryName, {String? args}) async {
    final path = "$binPath/$binaryName";
    logger.i("BinaryShell: Starting binary -> $binaryName (Args: $args)");

    await exec("mkdir -p $logPath");
    await exec("chmod +x $path");

    final logFile = "$logPath/$binaryName.log";
    // Comment: Execute detached with logging redirection to files
    await exec("($path ${args ?? ''} > $logFile 2>&1 &)");
  }

  Future<void> kill(String binaryName) async {
    logger.w("BinaryShell: Killing binary -> $binaryName");

    // Comment: Multi-stage aggressive kill sequence (SIGKILL)
    await exec("pkill -9 -f \"$binaryName\"");
    await exec("killall -9 $binaryName 2>/dev/null || true");

    final psOutput =
        await exec("ps -A | grep -i \"$binaryName\" | grep -v grep");
    if (psOutput.isNotEmpty) {
      final lines = psOutput.split('\n');
      for (var line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length > 1) {
          await exec("kill -9 ${parts[1]} 2>/dev/null || true");
        }
      }
    }
  }

  // --- Sub
  // Process Discovery
  Future<bool> isRunning(String binaryName) async {
    try {
      final pids = await exec("pgrep -f \"$binaryName\"");
      if (pids.trim().isNotEmpty) return true;

      final psGrep =
          await exec("ps -A | grep -i \"$binaryName\" | grep -v grep");
      return psGrep.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- Sub
  // Logging Utilities
  Future<String> getLogs(String binaryName) async {
    final file = "$logPath/$binaryName.log";
    try {
      if ((await exec("test -f $file && echo 'YES'")).contains("YES")) {
        final content = await exec("cat $file");
        if (content.trim().isNotEmpty) return content;
      }

      if (await isRunning(binaryName)) {
        return "Service is running. Waiting for logs...";
      }
      return "Waiting for logs...";
    } catch (e) {
      return "Log Error: $e";
    }
  }

  Future<void> clearLogs(String binaryName) async {
    final file = "$logPath/$binaryName.log";
    await exec("> $file");
  }
}

// ---- MAJOR ---
// Global Instances & Providers
final binaryShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Singleton Lifecycle
  return BinaryShellService(session);
});
