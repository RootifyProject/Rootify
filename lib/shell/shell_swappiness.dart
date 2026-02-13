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
// Bridge for VM Subsystem & Swap Configuration
class ShellSwappinessService extends BaseShellService {
  ShellSwappinessService(super.session);

  // --- Sub
  // Swappiness Intensity Control
  Future<int> getSwappiness() async {
    logger.d("SwappinessShell: Reading VM swappiness value...");
    try {
      final output =
          await exec("cat /proc/sys/vm/swappiness 2>/dev/null", silent: true);
      return int.tryParse(output.trim()) ?? 60;
    } catch (e, stack) {
      logger.e("SwappinessShell: Read error", e, stack, true);
      return 60;
    }
  }

  Future<void> setSwappiness(int value) async {
    // Comment: Clamping to 200 as some advanced kernels allow exceeding 100
    final val = value.clamp(0, 200);
    logger.i("SwappinessShell: Updating VM swappiness -> $val");
    const shellPath = "/data/adb/modules/rootify/shell";
    final result = await exec("sh $shellPath/SWAP-AGGRESIVE.sh $val");
    if (result.contains("ERROR")) {
      logger.e("SwappinessShell: Failed to set swappiness: $result", null, null,
          true);
    }
  }

  // --- Sub
  // VFS Cache Pressure Control
  Future<int> getVfsCachePressure() async {
    logger.d("SwappinessShell: Reading VFS cache pressure...");
    try {
      final output = await exec(
          "cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null",
          silent: true);
      return int.tryParse(output.trim()) ?? 100;
    } catch (e, stack) {
      logger.e("SwappinessShell: Read error", e, stack, true);
      return 100;
    }
  }

  Future<void> setVfsCachePressure(int value) async {
    final val = value.clamp(0, 1000);
    logger.i("SwappinessShell: Updating VFS cache pressure -> $val");
    const shellPath = "/data/adb/modules/rootify/shell";
    final result = await exec("sh $shellPath/VFS-CACHE.sh $val");
    if (result.contains("ERROR")) {
      logger.e("SwappinessShell: Failed to set VFS cache pressure: $result",
          null, null, true);
    }
  }

  // --- Sub
  // Dirty Page Ratio Control
  Future<int> getDirtyRatio() async {
    logger.d("SwappinessShell: Reading dirty ratio...");
    try {
      final output =
          await exec("cat /proc/sys/vm/dirty_ratio 2>/dev/null", silent: true);
      return int.tryParse(output.trim()) ?? 20;
    } catch (e, stack) {
      logger.e("SwappinessShell: Read error", e, stack, true);
      return 20;
    }
  }

  Future<void> setDirtyRatio(int value) async {
    final val = value.clamp(0, 100);
    logger.i("SwappinessShell: Updating dirty ratio -> $val");
    await exec("echo $val > /proc/sys/vm/dirty_ratio");
  }
}

// ---- MAJOR ---
// Global Providers
final swappinessShellProvider = Provider((ref) {
  final session = ShellSession(); // Comment: Reuses singleton shell bridge
  return ShellSwappinessService(session);
});
